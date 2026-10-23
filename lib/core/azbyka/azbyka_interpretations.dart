import 'package:html/dom.dart';

/// Толкование, привязанное к последнему стиху своего блока.
typedef AzbykaInterpretation = ({String text, String range});

/// Разбор святоотеческих толкований Азбуки: общий для чтения дня и Библии.
abstract final class AzbykaInterpretations {
  /// Ссылка на страницу первого из [slugs], найденного в списке
  /// толкователей страницы стихов. Порядок [slugs] — приоритет.
  static ({String href, String author})? interpreterLink(
    Document doc,
    List<String> slugs,
  ) {
    final links = doc.querySelectorAll('.interprets a[href]');
    for (final slug in slugs) {
      for (final a in links) {
        final href = a.attributes['href']!;
        if (!href.contains('/$slug/')) continue;
        return (
          href: href.startsWith('http') ? href : 'https://azbyka.ru$href',
          author: a.text.trim(),
        );
      }
    }
    return null;
  }

  /// Группирует `p.h5`/`p.txt` и привязывает комментарий к последнему стиху
  /// группы [chapter] книги [book]; [abbreviation] подписывает отрывок.
  ///
  /// `p.h5` без ссылки — подзаголовок следующего фрагмента того же стиха
  /// («раб», «Иисуса Христа»). Если стих разбит на фрагменты, каждый
  /// комментарий подписан своим фрагментом: без подписи было бы неясно,
  /// к каким словам он относится.
  static Map<int, AzbykaInterpretation> byVerse(
    Document doc, {
    required String book,
    required int chapter,
    required String abbreviation,
  }) {
    final result = <int, AzbykaInterpretation>{};
    var group = <int>[];
    var segments = <_Segment>[];
    var split = false;

    void flush() {
      final paragraphs = [
        for (final segment in segments)
          if (segment.paragraphs.isNotEmpty) ...[
            if (split && segment.fragment.isNotEmpty) '«${segment.fragment}»',
            ...segment.paragraphs,
          ],
      ];
      if (group.isNotEmpty && segments.any((s) => s.paragraphs.isNotEmpty)) {
        final range = group.length == 1
            ? '$abbreviation.$chapter:${group.first}'
            : '$abbreviation.$chapter:${group.first}–${group.last}';
        result[group.last] = (text: paragraphs.join('\n\n'), range: range);
      }
      group = [];
      segments = [];
      split = false;
    }

    for (final p in doc.querySelectorAll('p.h5, p.txt')) {
      if (p.classes.contains('txt')) {
        final text = _clean(p.text);
        if (group.isNotEmpty && text.isNotEmpty) {
          segments.last.paragraphs.add(text);
        }
        continue;
      }

      final ref = _verseRefOf(p);
      final fragment = _fragmentOf(p);
      if (ref == null) {
        // Подзаголовок до первого стиха — вступление к главе, не к стиху.
        if (group.isEmpty) continue;
        split = true;
        segments.add(_Segment(fragment));
        continue;
      }
      if (segments.any((s) => s.paragraphs.isNotEmpty)) flush();
      if (ref.book != book || ref.chapter != chapter) {
        // Блок на чужую главу: его комментарий не должен дописаться к
        // последнему стиху нашей.
        flush();
        continue;
      }
      group.add(ref.verse);
      // Подряд идущие стихи без комментария между ними — один фрагмент.
      if (segments.isNotEmpty && segments.last.paragraphs.isEmpty) {
        segments.last.fragment = '${segments.last.fragment} $fragment'.trim();
      } else {
        segments.add(_Segment(fragment));
      }
    }
    flush();

    return result;
  }

  static ({String book, int chapter, int verse})? _verseRefOf(
    Element paragraph,
  ) {
    for (final a in paragraph.querySelectorAll('a[href]')) {
      final m = RegExp(
        r'\?([A-Za-z0-9]+)\.(\d+):(\d+)',
      ).firstMatch(a.attributes['href']!);
      if (m == null) continue;
      return (
        book: m.group(1)!,
        chapter: int.parse(m.group(2)!),
        verse: int.parse(m.group(3)!),
      );
    }
    return null;
  }

  /// Слова стиха, к которым написан комментарий, без ссылки и хвостовой
  /// запятой: «Павел,» → «Павел».
  static String _fragmentOf(Element paragraph) {
    final quote = paragraph.querySelector('.quote');
    final raw = quote != null
        ? quote.text
        : paragraph.text.replaceFirst(RegExp(r'^\s*\S+\.\d+:\d+\.?'), '');
    return _clean(raw).replaceFirst(RegExp(r'[\s,;:–—-]+$'), '');
  }

  static String _clean(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _Segment {
  _Segment(this.fragment);

  String fragment;
  final paragraphs = <String>[];
}
