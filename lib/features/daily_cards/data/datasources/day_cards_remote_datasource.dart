import 'dart:async';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

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
    final dateStr = _formatDate(date);
    final uri = Uri.parse('https://azbyka.ru/days/$dateStr');

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException catch (e) {
      throw RemoteFetchException(FailureKind.network, e);
    } on SocketException catch (e) {
      throw RemoteFetchException(FailureKind.network, e);
    } on http.ClientException catch (e) {
      throw RemoteFetchException(FailureKind.network, e);
    }

    if (response.statusCode != 200) {
      throw RemoteFetchException(
        FailureKind.server,
        HttpException('azbyka.ru вернул ${response.statusCode}', uri: uri),
      );
    }

    try {
      final doc = html_parser.parse(response.body);
      return [
        _quoteCard(doc, dateStr),
        _sectionCard(doc, dateStr, type: 'advice', selector: '#sovet p'),
        _sectionCard(doc, dateStr, type: 'basics', selector: '#osnovy p'),
        _sectionCard(
          doc,
          dateStr,
          type: 'reading',
          selector: '#pritcha .brif p',
        ),
      ];
    } on FormatException catch (e) {
      // Селекторы не нашли блок — на azbyka.ru поменялась вёрстка.
      // Ретраить бессмысленно, поэтому unknown, а не server.
      throw RemoteFetchException(FailureKind.unknown, e);
    }
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
    final paragraphs = doc
        .querySelectorAll(selector)
        .map(_textWithBreaks)
        .where((t) => t.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) {
      throw FormatException('блок "$type" не найден на странице ($selector)');
    }
    return DayCardDto(
      id: '$type-$dateStr',
      type: type,
      body: paragraphs.join('\n\n'),
      source: _defaultSource,
    );
  }

  /// <br> не даёт пробела в Element.text — без замены соседние
  /// предложения слипаются. Заменяем на \n через реэкспорт фрагмента.
  static String _textWithBreaks(Element el) {
    final withBreaks = el.innerHtml
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    return html_parser.parseFragment(withBreaks).text?.trim() ?? '';
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
