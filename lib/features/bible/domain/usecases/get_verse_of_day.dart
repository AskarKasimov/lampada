import '../../../../core/result/result.dart';
import '../entities/daily_verse.dart';
import '../repositories/bible_repository.dart';
import '../verse_of_day.dart';

/// Стих дня на [date]: ссылка из подборки, текст из главы Синодального
/// перевода. Глава кэшируется репозиторием, поэтому повторный показ и
/// открытие этой главы во вкладке «Библия» работают без сети.
class GetVerseOfDay {
  const GetVerseOfDay(this._repository, {this.refFor = verseOfDayRefFor});

  final BibleRepository _repository;

  /// Выбор ссылки на день; подменяется в тестах.
  final VerseRef Function(DateTime date) refFor;

  Future<Result<DailyVerse>> call(DateTime date) async {
    final ref = refFor(date);
    final result = await _repository.getChapter(ref.book, ref.chapter);
    return switch (result) {
      Failure(failure: final failure) => Failure(failure),
      Success(value: final chapter) => _verseFrom(ref, {
        for (final verse in chapter.verses) verse.number: verse.text.trim(),
      }),
    };
  }

  Result<DailyVerse> _verseFrom(VerseRef ref, Map<int, String> texts) {
    final parts = [
      for (var number = ref.verse; number <= ref.to; number++) texts[number],
    ];
    // Нумерация стихов на сайте разошлась с подборкой: лучше не показать
    // карточку, чем показать чужой стих или обрывок отрывка.
    if (parts.any((text) => text == null || text.isEmpty)) {
      return Failure(AppFailure('Нет стихов $ref', kind: FailureKind.unknown));
    }
    return Success(
      DailyVerse(
        book: ref.book,
        chapter: ref.chapter,
        verse: ref.verse,
        endVerse: ref.to == ref.verse ? null : ref.to,
        text: _capitalized(parts.join(' ')),
      ),
    );
  }

  /// Стих, взятый с середины фразы («не бойся, ибо Я с тобою…»), на
  /// карточке начинается с заглавной, как отдельное высказывание.
  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
