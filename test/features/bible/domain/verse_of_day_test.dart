import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/bible/domain/entities/bible_book.dart';
import 'package:lampada/features/bible/domain/verse_of_day.dart';

void main() {
  test('каждая ссылка подборки указывает на существующую главу', () {
    final books = {for (final book in bibleBooks) book.code: book};
    for (final ref in verseOfDayRefs) {
      final book = books[ref.book];
      expect(book, isNotNull, reason: '${ref.book} нет в каталоге');
      expect(ref.chapter, inInclusiveRange(1, book!.chapterCount));
      expect(ref.verse, greaterThan(0));
      // Отрывок держит одну законченную мысль и остаётся коротким: второй
      // стих добавляется только когда без него мысль не закончена.
      expect(ref.to, inInclusiveRange(ref.verse, ref.verse + 1));
    }
  });

  test('в подборке нет повторов', () {
    final keys = verseOfDayRefs
        .map((ref) => '${ref.book}.${ref.chapter}:${ref.verse}')
        .toList();
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('стих дня один на весь день, в любое время суток', () {
    expect(
      verseOfDayRefFor(DateTime(2026, 10, 23, 0, 5)),
      verseOfDayRefFor(DateTime(2026, 10, 23, 23, 55)),
    );
  });

  test('за полный круг каждый стих выходит ровно один раз', () {
    final start = DateTime(2026, 1, 1);
    final seen = [
      for (var i = 0; i < verseOfDayRefs.length; i++)
        verseOfDayRefFor(DateTime(start.year, start.month, start.day + i)),
    ];
    expect(seen.toSet(), hasLength(verseOfDayRefs.length));
  });

  test('соседние дни берут стихи из разных книг', () {
    final start = DateTime(2026, 3, 1);
    for (var i = 0; i < 30; i++) {
      final today = verseOfDayRefFor(
        DateTime(start.year, start.month, start.day + i),
      );
      final tomorrow = verseOfDayRefFor(
        DateTime(start.year, start.month, start.day + i + 1),
      );
      expect(today.book, isNot(tomorrow.book), reason: 'день $i');
    }
  });

  test('переход на летнее время не сбивает выбор дня', () {
    // В ночь на 29 марта 2026 в Европе сутки короче на час.
    expect(
      verseOfDayRefFor(DateTime(2026, 3, 29, 12)),
      isNot(verseOfDayRefFor(DateTime(2026, 3, 28, 12))),
    );
    expect(
      verseOfDayRefFor(DateTime(2026, 3, 30, 1)),
      isNot(verseOfDayRefFor(DateTime(2026, 3, 29, 23))),
    );
  });

  test('отрывки подборки не пересекаются', () {
    final taken = <String>{};
    for (final ref in verseOfDayRefs) {
      for (var n = ref.verse; n <= ref.to; n++) {
        expect(
          taken.add('${ref.book}.${ref.chapter}:$n'),
          isTrue,
          reason: '${ref.book}.${ref.chapter}:$n встречается дважды',
        );
      }
    }
  });

  test('Пс. 36:5 идёт вместе с 36:6: стих обрывается на запятой', () {
    expect(verseOfDayRefs, contains(const VerseRef('Ps', 36, 5, to: 6)));
    expect(verseOfDayRefs, isNot(contains(const VerseRef('Ps', 36, 5))));
  });

  test('законченная мысль стоит одна, даже на «;» или «:»', () {
    expect(verseOfDayRefs, contains(const VerseRef('Mt', 11, 28)));
    expect(verseOfDayRefs, contains(const VerseRef('Ps', 22, 1)));
    expect(verseOfDayRefs, contains(const VerseRef('Lk', 6, 37)));
    expect(verseOfDayRefs, contains(const VerseRef('Eph', 4, 31)));
  });
}
