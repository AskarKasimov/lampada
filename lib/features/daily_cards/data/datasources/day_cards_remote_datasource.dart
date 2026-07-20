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
/// (цитата/совет/основы/притча) лежит на одной странице.
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
        _sectionCard(doc, dateStr, type: 'reading', selector: '#pritcha .brif'),
        _questionCard(doc, dateStr),
      ];
      netLog('разобрано ${cards.length} карточек '
          'за ${elapsed.elapsedMilliseconds}мс суммарно');
      return cards;
    } on FormatException catch (e) {
      // Вёрстка azbyka.ru поменялась — ретраить бессмысленно,
      // поэтому unknown, а не server.
      netLog('разметка не разобралась → unknown: $e');
      throw RemoteFetchException(FailureKind.unknown, e);
    }
  }

  /// Виджет «Вопрос дня» имеет общий `class="widget"` с другими блоками,
  /// поэтому цепляемся за уникальный класс ссылки `az-qod-link`. Ответ живёт
  /// на отдельной странице по этой же ссылке и здесь не запрашивается.
  DayCardDto _questionCard(Document doc, String dateStr) {
    final link = doc.querySelector('a.az-qod-link');
    final body = link?.text.trim() ?? '';
    if (body.isEmpty) {
      throw const FormatException('блок "Вопрос дня" не найден на странице');
    }
    return DayCardDto(
      id: 'question-$dateStr',
      type: 'question',
      body: body,
      source: _defaultSource,
    );
  }

  DayCardDto _quoteCard(Document doc, String dateStr) {
    final box = doc.querySelector('div.widget.quote-of-day .box');
    final paragraphs = box?.querySelectorAll('p') ?? const <Element>[];
    if (paragraphs.length < 2) {
      throw const FormatException('блок "Цитата дня" не найден на странице');
    }
    final body = _textWithBreaks(paragraphs[0]);
    final author = paragraphs[1].querySelector('a')?.text.trim();
    return DayCardDto(
      id: 'quote-$dateStr',
      type: 'quote',
      body: body,
      source: (author == null || author.isEmpty) ? _defaultSource : author,
    );
  }

  DayCardDto _sectionCard(
    Document doc,
    String dateStr, {
    required String type,
    required String selector,
  }) {
    final container = doc.querySelector(selector);
    if (container == null) {
      throw FormatException('блок "$type" не найден на странице ($selector)');
    }
    final paragraphs = _paragraphsFrom(container);
    if (paragraphs.isEmpty) {
      throw FormatException('блок "$type" пуст ($selector)');
    }
    return DayCardDto(
      id: '$type-$dateStr',
      type: type,
      body: paragraphs.join('\n\n'),
      source: _defaultSource,
    );
  }

  /// Абзацы блока. Азбука верстает эти секции двумя способами, и день ото дня
  /// они меняются: то текст разложен по <p>, то лежит в контейнере голым и
  /// разделён <br>. Знаем только один вариант — приложение уходит в вечный
  /// офлайн в тот день, когда придёт второй.
  static List<String> _paragraphsFrom(Element container) {
    // Заголовок секции («Практический совет») — не контент.
    container.querySelector('h2')?.remove();

    final tagged = container
        .querySelectorAll('p')
        .map(_textWithBreaks)
        .where((t) => t.isNotEmpty)
        .toList();
    if (tagged.isNotEmpty) return tagged;

    return _textWithBreaks(container)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// <br> не даёт пробела в Element.text — заменяем на \n, иначе соседние
  /// предложения слипаются.
  static String _textWithBreaks(Element el) {
    final withBreaks = el.innerHtml
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    return html_parser.parseFragment(withBreaks).text?.trim() ?? '';
  }
}
