import 'split_course_text.dart';

/// Делит текст цитаты, совета или притчи на страницы «Мудрости дня».
///
/// В отличие от курса, где каждое предложение идёт отдельной карточкой,
/// здесь предложения собираются в страницы до [maxChars] символов: короткая
/// цитата остаётся целой, а длинный совет не требует полноэкранного режима.
/// Страницы выравниваются по длине, чтобы не оставлять короткий хвост.
/// Вопрос в начале длинного совета («Как …?») идёт отдельной страницей:
/// у Азбуки советы часто построены как вопрос и ответ.
///
/// Предложение длиннее [maxChars] остаётся целым: читалка покажет превью
/// и предложит открыть его полностью.
List<String> splitDayCardText(String text, {int maxChars = 280}) {
  if (_length(text) <= maxChars) return [text.trim()];
  final sentences = splitCourseText(text);
  if (sentences.length < 2) return [text.trim()];

  final pages = <String>[];
  var rest = sentences;
  if (_endsWithQuestion(sentences.first)) {
    pages.add(sentences.first.trim());
    rest = sentences.sublist(1);
  }
  return [...pages, ..._pack(rest, maxChars)];
}

List<String> _pack(List<String> sentences, int maxChars) {
  final total = _length(sentences.join());
  final target = total / (total / maxChars).ceil();
  final pages = <String>[];
  var current = '';
  for (final sentence in sentences) {
    final joined = _length(current + sentence);
    final closeBefore =
        current.trim().isNotEmpty &&
        (joined > maxChars ||
            // Перебор над целевой длиной больше недобора: лучше начать
            // новую страницу перед этим предложением.
            (joined > target && joined - target > target - _length(current)));
    if (closeBefore) {
      pages.add(current.trim());
      current = '';
    }
    current += sentence;
  }
  if (current.trim().isNotEmpty) pages.add(current.trim());
  return pages;
}

int _length(String text) => text.trim().runes.length;

bool _endsWithQuestion(String sentence) =>
    RegExp(r'\?[»”"’)\]]*$').hasMatch(sentence.trim());
