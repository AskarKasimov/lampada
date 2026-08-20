import 'dart:async';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../../core/format/date_key.dart';
import '../../../../core/log/net_log.dart';
import '../../../../core/network/remote_fetch_exception.dart';
import '../../../../core/result/result.dart';
import '../dto/day_card_dto.dart';
import '../dto/day_dto.dart';

/// Источник дневного контента. Реализация ниже скрейпит azbyka.ru —
/// абстракция позволяет подменить её в тестах репозитория.
abstract interface class DayCardsRemoteDatasource {
  /// [timeout] задаёт вызывающий: бюджетом на загрузку владеет репозиторий,
  /// датасорс лишь исполняет отведённое ему время.
  Future<DayDto> fetch(DateTime date, {required Duration timeout});
}

/// Скрейпит https://azbyka.ru/days/{yyyy-MM-dd} — вся дневная разметка
/// (цитата/совет/основы/чтения/вопрос) лежит на одной странице.
///
/// Отсутствующая секция карточку не создаёт, но и день не роняет: Азбука
/// публикует не все разделы каждый день, а раньше пропажа любого из пяти
/// уводила приложение в офлайн-экран при живом интернете. Сбоем считается
/// только страница, где не нашлось ни одной секции.
class AzbykaDayCardsRemoteDatasource implements DayCardsRemoteDatasource {
  AzbykaDayCardsRemoteDatasource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _defaultSource = 'Азбука веры';

  @override
  Future<DayDto> fetch(DateTime date, {required Duration timeout}) async {
    final dateStr = dateKey(date);
    final uri = Uri.parse('https://azbyka.ru/days/$dateStr');
    final elapsed = Stopwatch()..start();
    netLog('GET $uri (отведено ${timeout.inMilliseconds}мс)');

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException catch (e) {
      netLog('таймаут на ${elapsed.elapsedMilliseconds}мс → network');
      throw RemoteFetchException(FailureKind.network, e);
    } on SocketException catch (e) {
      netLog('сокет упал на ${elapsed.elapsedMilliseconds}мс → network: $e');
      throw RemoteFetchException(FailureKind.network, e);
    } on http.ClientException catch (e) {
      netLog('клиент упал на ${elapsed.elapsedMilliseconds}мс → network: $e');
      throw RemoteFetchException(FailureKind.network, e);
    }

    netLog(
      'ответ ${response.statusCode}, ${response.bodyBytes.length}Б '
      'за ${elapsed.elapsedMilliseconds}мс',
    );

    if (response.statusCode != 200) {
      throw RemoteFetchException(
        FailureKind.server,
        HttpException('azbyka.ru вернул ${response.statusCode}', uri: uri),
      );
    }

    try {
      final doc = html_parser.parse(response.body);
      final cards = [
        _quoteCard(doc, dateStr),
        _sectionCard(doc, dateStr, type: 'advice', selector: '#sovet'),
        _basicsCard(doc, dateStr),
        _readingCard(doc, dateStr),
        _parableCard(doc, dateStr),
      ].nonNulls.toList();

      // Пустая страница — это уже сломанная вёрстка, а не неполный день.
      if (cards.isEmpty) {
        throw const FormatException('ни одной секции дня на странице');
      }

      final day = DayDto(
        cards: cards,
        week: _weekOf(doc),
        title: _titleOf(doc),
        isFast: _isFastDay(doc),
        storyUrl: _storyUrlOf(doc),
      );

      netLog(
        'разобрано ${cards.length} карточек '
        '(${cards.map((c) => c.type).join(', ')}), '
        'день: ${day.title ?? '—'} / ${day.week ?? '—'}'
        '${day.isFast ? ' / постный' : ''} '
        'за ${elapsed.elapsedMilliseconds}мс суммарно',
      );
      return day;
    } on FormatException catch (e) {
      // Вёрстка azbyka.ru поменялась — ретраить бессмысленно,
      // поэтому unknown, а не server.
      netLog('разметка не разобралась → unknown: $e');
      throw RemoteFetchException(FailureKind.unknown, e);
    }
  }

  /// Карточка чтения дня несёт только ссылку на отрывок — стихи и толкование
  /// лежат на других страницах Азбуки и грузятся ридером по требованию.
  DayCardDto? _readingCard(Document doc, String dateStr) {
    final block = doc.querySelector('#chteniya');
    if (block == null) {
      netLog('нет секции "reading" (#chteniya) — пропускаем');
      return null;
    }
    final link = _liturgyGospelLink(block);
    if (link == null) {
      netLog('в #chteniya нет евангельского чтения — пропускаем');
      return null;
    }
    final reference = _referenceFrom(link);
    if (reference == null) {
      netLog('ссылка чтения не разобралась: ${link.attributes['href']}');
      return null;
    }
    return DayCardDto(
      id: 'reading-$dateStr',
      type: 'reading',
      // Текст ссылки — уже человекочитаемое «Ин.10:1–9».
      body: link.text.trim(),
      source: _defaultSource,
      reference: reference,
    );
  }

  /// Притча дня. От [_sectionCard] отличается подписью: у части дней притча
  /// заканчивается абзацем с автором, и он обязан попасть в source — карточка
  /// и так печатает «— {source}» под телом, иначе автор оказался бы на экране
  /// дважды и по-разному.
  DayCardDto? _parableCard(Document doc, String dateStr) {
    final container = doc.querySelector('#pritcha');
    if (container == null) {
      netLog('нет секции "parable" (#pritcha) — пропускаем');
      return null;
    }
    // Строго до _paragraphsFrom: подпись вырезается из дерева, иначе она
    // же станет последним абзацем тела.
    final author = _attributionOf(container);
    final paragraphs = _paragraphsFrom(container);
    if (paragraphs.isEmpty) {
      netLog('секция "parable" пуста — пропускаем');
      return null;
    }
    return DayCardDto(
      id: 'parable-$dateStr',
      type: 'parable',
      body: paragraphs.join('\n\n'),
      source: author ?? _defaultSource,
    );
  }

  /// Подпись автора притчи — последний абзац, выключенный вправо.
  ///
  /// Азбука ставит её не всегда: на семи проверенных датах подпись была у
  /// двух. Опираемся на выключку, а не на позицию: у части притч первый абзац
  /// выключен по центру — это их собственный заголовок («Хитрый архитектор»),
  /// и он часть текста, а не подпись.
  static String? _attributionOf(Element container) {
    final paragraphs = container.querySelectorAll('p');
    if (paragraphs.isEmpty) return null;

    final last = paragraphs.last;
    final style = (last.attributes['style'] ?? '').replaceAll(' ', '');
    if (!style.contains('text-align:right')) return null;

    last.remove();
    // «(см. иллюстрацию к этой притче)» — ссылка на страницу сайта, внутри
    // приложения вести по ней некуда.
    final text = _textWithBreaks(
      last,
    ).replaceFirst(RegExp(r'\s*\(\s*см\..*$', dotAll: true), '').trim();
    return text.isEmpty ? null : text;
  }

  /// «Основы» с названием темы.
  ///
  /// Название нужно входу в курс на «Сегодня»: без него блок обещал «Основы
  /// веры» и ничего больше. Берём `<strong>` из первого абзаца, а не режем
  /// текст по первой точке: Азбука выделяет заголовок разметкой, а в самих
  /// названиях встречаются сокращения с точкой внутри.
  DayCardDto? _basicsCard(Document doc, String dateStr) {
    final title = _cleaned(doc.querySelector('#osnovy p strong'));
    final card = _sectionCard(
      doc,
      dateStr,
      type: 'basics',
      selector: '#osnovy',
    );
    return card?.copyWith(title: title);
  }

  /// Седмица церковного года: «Седмица 10-я по Пятидесятнице».
  ///
  /// Внутри `.shadow` лежат распорки `.lc`/`.rc` с неразрывными пробелами,
  /// а сам текст разорван ссылками («<a>Седмица 2</a>-я <a>Великого поста</a>»),
  /// поэтому берём текст всего блока и схлопываем пробелы.
  static String? _weekOf(Document doc) =>
      _cleaned(doc.querySelector('.day__post-wp .shadow'));

  /// Первая память дня: «Прп. Льва́, епископа Ката́нского».
  ///
  /// Год жизни в `.secondary-content` отбрасываем: в шапке важно, чей это
  /// день, а не когда он был, и «(ок. 780)» только удлиняет строку, которая
  /// и так набрана крупно.
  static String? _titleOf(Document doc) {
    final item = doc.querySelector('.day__text ul li');
    if (item == null) return null;
    item.querySelectorAll('.secondary-content').forEach((e) => e.remove());
    return _cleaned(item);
  }

  /// Ссылка на страницу праздника/святого — там лежит рассказ о дне.
  ///
  /// Тот же `<li>`, что читает [_titleOf]. Первой ссылкой в нём иногда стоит
  /// иконка-легенда («что означают эти значки», ведёт на `p-znaki-prazdnikov`)
  /// — у неё нет текста, только `<img>`. Берём первую ссылку с НЕПУСТЫМ
  /// текстом: это и есть память дня, а не пояснение к значку.
  static String? _storyUrlOf(Document doc) {
    final item = doc.querySelector('.day__text ul li');
    if (item == null) return null;
    final link = item
        .querySelectorAll('a[href]')
        .where((a) => a.text.trim().isNotEmpty)
        .firstOrNull;
    final href = link?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    final uri = Uri.tryParse(href);
    if (uri == null) return null;
    if (uri.hasAuthority || uri.hasScheme) {
      return uri.scheme == 'https' && uri.host == 'azbyka.ru'
          ? uri.toString()
          : null;
    }
    return Uri.parse('https://azbyka.ru').resolveUri(uri).toString();
  }

  /// Постный ли день. Пометка стоит ссылкой на календарь постов в первом
  /// абзаце `.day__text`; опираемся на href, а не на текст, потому что рядом
  /// в том же абзаце живёт глас и порядок слов у Азбуки плавает.
  static bool _isFastDay(Document doc) =>
      doc.querySelector('.day__text a[href*="kalendar-postov"]') != null;

  /// Текст элемента со схлопнутыми пробелами, включая неразрывные.
  static String? _cleaned(Element? el) {
    if (el == null) return null;
    final text = el.text
        .replaceAll(' ', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.isEmpty ? null : text;
  }

  /// Первое евангельское чтение литургии.
  ///
  /// Пометка «Лит.» отделяет литургийные чтения от утрени. Утреня для
  /// новоначального избыточна, а её Евангелие стоит в блоке ПЕРВЫМ и без
  /// этой отсечки перехватывало бы выбор. Дней без пометки большинство —
  /// там литургийное чтение и есть первое в блоке. Чтения святому идут
  /// после основного, поэтому «первое подходящее» — верное правило.
  static Element? _liturgyGospelLink(Element block) {
    var afterLiturgy = false;
    Element? firstGospel;
    Element? firstAfterLiturgy;

    void walk(Node node) {
      if (node is Text) {
        if (_liturgyMarker.hasMatch(node.text)) afterLiturgy = true;
        return;
      }
      if (node is! Element) return;
      // Азбука верстает пометку ссылкой: `<a href="/liturgiya">Лит</a>.` —
      // точка оказывается в соседнем узле, и поиск «Лит.» по тексту одного
      // узла промахивался. Тогда выбиралось Евангелие УТРЕНИ, потому что оно
      // стоит в блоке первым.
      if (node.localName == 'a' &&
          (node.attributes['href'] ?? '').contains('/liturgiya')) {
        afterLiturgy = true;
      }
      if (node.classes.contains('bibref') && _isGospelLink(node)) {
        firstGospel ??= node;
        if (afterLiturgy) firstAfterLiturgy ??= node;
      }
      for (final child in node.nodes) {
        walk(child);
      }
    }

    for (final child in block.nodes) {
      walk(child);
    }
    return firstAfterLiturgy ?? firstGospel;
  }

  static final _liturgyMarker = RegExp(r'Лит\s*\.');

  /// Апостол и ветхозаветные паремии в ридер не идут: по продуктовому решению
  /// показываем только Евангелие дня.
  static const _gospelSlugs = {'Mt', 'Mk', 'Lk', 'Jn'};

  static final _referencePattern = RegExp(
    r'\?([A-Za-z0-9]+)\.(\d+:\d+(?:[-–]\d+(?::\d+)?)?)',
  );

  static bool _isGospelLink(Element link) {
    final match = _referencePattern.firstMatch(link.attributes['href'] ?? '');
    return match != null && _gospelSlugs.contains(match.group(1));
  }

  /// `https://azbyka.ru/biblia/?Jn.10:1-9` → `Jn.10:1-9`. Тире нормализуем:
  /// в ссылках Азбуки встречается и дефис, и типографское «–».
  static String? _referenceFrom(Element link) {
    final match = _referencePattern.firstMatch(link.attributes['href'] ?? '');
    if (match == null) return null;
    return '${match.group(1)}.${match.group(2)!.replaceAll('–', '-')}';
  }

  DayCardDto? _quoteCard(Document doc, String dateStr) {
    final box = doc.querySelector('div.widget.quote-of-day .box');
    final paragraphs = box?.querySelectorAll('p') ?? const <Element>[];
    if (paragraphs.isEmpty) {
      netLog('нет секции "quote" — пропускаем');
      return null;
    }
    final body = _textWithBreaks(paragraphs[0]);
    if (body.isEmpty) {
      netLog('секция "quote" пуста — пропускаем');
      return null;
    }
    // Второй абзац с автором необязателен: цитата без подписи — всё ещё
    // цитата, а индекс без проверки падал бы на такой вёрстке.
    final author = paragraphs.length > 1
        ? paragraphs[1].querySelector('a')?.text.trim()
        : null;
    return DayCardDto(
      id: 'quote-$dateStr',
      type: 'quote',
      body: body,
      source: (author == null || author.isEmpty) ? _defaultSource : author,
    );
  }

  DayCardDto? _sectionCard(
    Document doc,
    String dateStr, {
    required String type,
    required String selector,
  }) {
    final container = doc.querySelector(selector);
    if (container == null) {
      netLog('нет секции "$type" ($selector) — пропускаем');
      return null;
    }
    final paragraphs = _paragraphsFrom(container);
    if (paragraphs.isEmpty) {
      netLog('секция "$type" пуста ($selector) — пропускаем');
      return null;
    }
    return DayCardDto(
      id: '$type-$dateStr',
      type: type,
      body: paragraphs.join('\n\n'),
      source: _defaultSource,
    );
  }

  /// Абзацы блока. Азбука верстает эти секции по-разному и меняет разметку
  /// день ото дня — знание одного варианта каждый раз выходит боком:
  ///
  /// * текст разложен по `<p>`;
  /// * текст лежит в контейнере голым и разделён `<br>`;
  /// * вопрос в `<p>`, а весь ответ — списком `<ul><li>`.
  ///
  /// Третий вариант ловил нас молча и хуже всех: сбора одних `<p>` хватало,
  /// чтобы вернуть непустой результат, поэтому «совет дня» показывал вопрос
  /// без ответа и выглядел рабочим.
  ///
  /// Поэтому собираем в порядке документа и `<p>`, и `<li>`. Элемент с
  /// вложенными `p`/`ul`/`ol` пропускаем: у Азбуки встречается кривое
  /// `<p><p>…</p></p>`, и без этой отсечки текст задваивался бы.
  static List<String> _paragraphsFrom(Element container) {
    // Заголовок секции («Практический совет») — не контент.
    container.querySelector('h2')?.remove();

    final parts = <String>[];
    for (final el in container.querySelectorAll('p, li')) {
      if (el.querySelector('p, li, ul, ol') != null) continue;
      final text = _textWithBreaks(el);
      if (text.isNotEmpty) parts.add(text);
    }
    if (parts.isNotEmpty) return parts;

    return _textWithBreaks(container)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// <br> не даёт пробела в Element.text — заменяем на \n, иначе соседние
  /// предложения слипаются.
  static String _textWithBreaks(Element el) {
    final withBreaks = el.innerHtml.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    return html_parser.parseFragment(withBreaks).text?.trim() ?? '';
  }
}
