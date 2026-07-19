import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../dto/day_card_dto.dart';

/// Источник дневного контента. Реализация ниже скрейпит azbyka.ru —
/// абстракция позволяет подменить её в тестах репозитория.
abstract interface class DayCardsRemoteDatasource {
  Future<List<DayCardDto>> fetch(DateTime date);
}

/// Скрейпит https://azbyka.ru/days/{yyyy-MM-dd} — вся дневная разметка
/// (цитата/совет/основы/притча) лежит на одной странице.
class AzbykaDayCardsRemoteDatasource implements DayCardsRemoteDatasource {
  AzbykaDayCardsRemoteDatasource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _defaultSource = 'Азбука веры';

  @override
  Future<List<DayCardDto>> fetch(DateTime date) async {
    final dateStr = _formatDate(date);
    final uri = Uri.parse('https://azbyka.ru/days/$dateStr');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw HttpException(
        'azbyka.ru вернул ${response.statusCode}',
        uri: uri,
      );
    }
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
