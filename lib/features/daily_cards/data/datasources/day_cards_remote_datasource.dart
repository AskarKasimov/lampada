import 'dart:async';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../../core/format/date_key.dart';
import '../../../../core/log/net_log.dart';
import '../../../../core/result/result.dart';
import '../dto/day_card_dto.dart';

/// Сбой похода в сеть с уже определённым видом. Знание про `dart:io` и `http`
/// заканчивается здесь — репозиторий выше видит только [FailureKind].
class RemoteFetchException implements Exception {
  const RemoteFetchException(this.kind, this.cause);

  final FailureKind kind;
  final Object cause;

  @override
  String toString() => 'RemoteFetchException(${kind.name}, $cause)';
}

/// Источник дневного контента. Реализация ниже скрейпит azbyka.ru —
/// абстракция позволяет подменить её в тестах репозитория.
abstract interface class DayCardsRemoteDatasource {
  /// [timeout] задаёт вызывающий: бюджетом на загрузку владеет репозиторий,
  /// датасорс лишь исполняет отведённое ему время.
  Future<List<DayCardDto>> fetch(DateTime date, {required Duration timeout});
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
  Future<List<DayCardDto>> fetch(
    DateTime date, {
    required Duration timeout,
  }) async {
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
        _sectionCard(doc, dateStr, type: 'basics', selector: '#osnovy'),
        _readingCard(doc, dateStr),
        _questionCard(doc, dateStr),
      ].nonNulls.toList();

      // Пустая страница — это уже сломанная вёрстка, а не неполный день.
      if (cards.isEmpty) {
        throw const FormatException('ни одной секции дня на странице');
      }

      netLog(
        'разобрано ${cards.length} карточек '
        '(${cards.map((c) => c.type).join(', ')}) '
        'за ${elapsed.elapsedMilliseconds}мс суммарно',
      );
      return cards;
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

  /// Вопрос дня лежит в виджете с неуникальным классом, поэтому опираемся
  /// на уникальный класс самой ссылки. Ответ на отдельной странице намеренно
  /// не загружаем: карточка — вопрос для размышления, без второго запроса.
  DayCardDto? _questionCard(Document doc, String dateStr) {
    final body = doc.querySelector('a.az-qod-link')?.text.trim() ?? '';
    if (body.isEmpty) {
      netLog('нет секции "question" — пропускаем');
      return null;
    }
    return DayCardDto(
      id: 'question-$dateStr',
      type: 'question',
      body: body,
      source: _defaultSource,
    );
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
