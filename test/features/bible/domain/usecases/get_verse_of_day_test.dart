import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bible/domain/bible_chapter_statuses.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/domain/entities/daily_verse.dart';
import 'package:lampada/features/bible/domain/repositories/bible_repository.dart';
import 'package:lampada/features/bible/domain/usecases/get_verse_of_day.dart';
import 'package:lampada/features/bible/domain/verse_of_day.dart';

class _FakeRepository implements BibleRepository {
  _FakeRepository(this.result);

  final Result<BibleChapter> result;
  final requested = <(String, int)>[];

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async {
    requested.add((book, chapter));
    return result;
  }

  @override
  Future<Result<BibleChapterStatuses>> getChapterStatuses() =>
      throw UnimplementedError();

  @override
  Future<Result<void>> markChapterRead(String book, int chapter) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> saveChapterProgress(
    String book,
    int chapter,
    BibleChapterProgress progress,
  ) => throw UnimplementedError();
}

void main() {
  final date = DateTime(2026, 10, 23, 9);
  final ref = verseOfDayRefFor(date);

  test('берёт стих дня из главы Синодального перевода', () async {
    final repository = _FakeRepository(
      Success(
        BibleChapter(
          book: ref.book,
          number: ref.chapter,
          verses: [
            for (var n = 1; n <= ref.to + 1; n++)
              BibleVerse(number: n, text: '  Стих $n  '),
          ],
        ),
      ),
    );

    final result = await GetVerseOfDay(repository)(date);

    expect(repository.requested, [(ref.book, ref.chapter)]);
    final verse = (result as Success<DailyVerse>).value;
    expect(verse.book, ref.book);
    expect(verse.chapter, ref.chapter);
    expect(verse.verse, ref.verse);
    expect(
      verse.text,
      [for (var n = ref.verse; n <= ref.to; n++) 'Стих $n'].join(' '),
    );
  });

  test('ошибка загрузки главы уходит наружу как есть', () async {
    const failure = AppFailure('Нет сети', kind: FailureKind.network);
    final result = await GetVerseOfDay(_FakeRepository(const Failure(failure)))(
      date,
    );

    expect((result as Failure<DailyVerse>).failure, failure);
  });

  test('если стиха в главе нет, это сбой, а не пустая карточка', () async {
    final result = await GetVerseOfDay(
      _FakeRepository(
        Success(
          BibleChapter(
            book: ref.book,
            number: ref.chapter,
            verses: const [BibleVerse(number: 999, text: 'Чужой стих')],
          ),
        ),
      ),
    )(date);

    expect(result, isA<Failure<DailyVerse>>());
  });

  test('отрывок из нескольких стихов склеивается в одну мысль', () async {
    final repository = _FakeRepository(
      const Success(
        BibleChapter(
          book: 'Ps',
          number: 36,
          verses: [
            BibleVerse(number: 4, text: 'Утешайся Господом.'),
            BibleVerse(
              number: 5,
              text: 'Предай Господу путь твой и уповай на Него, и Он совершит,',
            ),
            BibleVerse(number: 6, text: ' и выведет, как свет, правду твою '),
            BibleVerse(number: 7, text: 'Покорись Господу.'),
          ],
        ),
      ),
    );

    final result = await GetVerseOfDay(
      repository,
      refFor: (_) => const VerseRef('Ps', 36, 5, to: 6),
    )(date);

    final verse = (result as Success<DailyVerse>).value;
    expect(verse.verse, 5);
    expect(verse.endVerse, 6);
    expect(
      verse.text,
      'Предай Господу путь твой и уповай на Него, и Он совершит, '
      'и выведет, как свет, правду твою',
    );
  });

  test('если стиха из отрывка нет, это сбой, а не обрывок', () async {
    final result = await GetVerseOfDay(
      _FakeRepository(
        const Success(
          BibleChapter(
            book: 'Ps',
            number: 36,
            verses: [BibleVerse(number: 5, text: 'Предай Господу путь твой,')],
          ),
        ),
      ),
      refFor: (_) => const VerseRef('Ps', 36, 5, to: 6),
    )(date);

    expect(result, isA<Failure<DailyVerse>>());
  });

  test('стих с середины фразы начинается с заглавной буквы', () async {
    final result = await GetVerseOfDay(
      _FakeRepository(
        const Success(
          BibleChapter(
            book: 'Is',
            number: 41,
            verses: [BibleVerse(number: 10, text: 'не бойся, ибо Я с тобою.')],
          ),
        ),
      ),
      refFor: (_) => const VerseRef('Is', 41, 10),
    )(date);

    expect(
      (result as Success<DailyVerse>).value.text,
      'Не бойся, ибо Я с тобою.',
    );
  });
}
