import '../../../../core/result/result.dart';
import '../entities/daily_verse.dart';
import '../repositories/bible_repository.dart';
import '../verse_of_day.dart';

/// Стих дня на [date]: ссылка из подборки, текст из главы Синодального
/// перевода. Глава кэшируется репозиторием, поэтому повторный показ и
/// открытие этой главы во вкладке «Библия» работают без сети.
class GetVerseOfDay {
  const GetVerseOfDay(this._repository);

  final BibleRepository _repository;

  Future<Result<DailyVerse>> call(DateTime date) async {
    final ref = verseOfDayRefFor(date);
    final result = await _repository.getChapter(ref.book, ref.chapter);
    return switch (result) {
      Failure(failure: final failure) => Failure(failure),
      Success(value: final chapter) => switch (chapter.verses
          .where((verse) => verse.number == ref.verse)
          .firstOrNull) {
        final verse? => Success(
          DailyVerse(
            book: ref.book,
            chapter: ref.chapter,
            verse: ref.verse,
            text: verse.text.trim(),
          ),
        ),
        // Нумерация стихов на сайте разошлась с подборкой: лучше не
        // показать карточку, чем показать чужой стих.
        null => Failure(
          AppFailure(
            'Нет стиха ${ref.book}.${ref.chapter}:${ref.verse}',
            kind: FailureKind.unknown,
          ),
        ),
      },
    };
  }
}
