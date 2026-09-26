/// Одно предложение — одна карточка. Длинное предложение остаётся целым:
/// читалка покажет превью и предложит открыть его полностью.
List<String> splitCourseText(String text) {
  if (text.isEmpty) return [''];
  final endings = RegExp(r'[.!?…]+[»”"’)\]]*(?:\s+|$)');
  final chunks = <String>[];
  var start = 0;
  for (final match in endings.allMatches(text)) {
    if (text[match.start] == '.' &&
        (match.start + 1 == text.length || text[match.start + 1] != '.')) {
      final word = RegExp(
        r'[А-Яа-яЁёA-Za-z]+$',
      ).firstMatch(text.substring(start, match.start))?.group(0)?.toLowerCase();
      // В церковных текстах сокращения встречаются перед именами и ссылками.
      if (_abbreviations.contains(word)) continue;
    }
    chunks.add(text.substring(start, match.end));
    start = match.end;
  }
  if (start < text.length) chunks.add(text.substring(start));
  return chunks;
}

const _abbreviations = {
  'св',
  'прп',
  'ап',
  'митр',
  'еп',
  'прот',
  'архим',
  'сщмч',
  'блж',
  'мф',
  'мк',
  'лк',
  'ин',
  'рим',
  'кор',
  'т',
  'е',
  'д',
  'г',
  'ст',
  'см',
  'др',
  'им',
  'проф',
};
