import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/bible/domain/entities/bible_book.dart';

void main() {
  test('каталог покрывает все 77 книг Азбуки, включая неканонические', () {
    expect(bibleBooks, hasLength(77));
    expect(bibleBooks.map((book) => book.code).toSet(), hasLength(77));
    expect(bibleBooks.every((book) => book.chapterCount > 0), isTrue);
    expect(bibleBooks.first.code, 'Gen');
    expect(bibleBooks.last.code, 'Apok');
    expect(
      bibleBooks.map((book) => book.code),
      containsAll(['Tov', 'pJer', '3Ezr']),
    );
  });

  test('всего в каталоге 1361 глава: от неё считается доля прочитанного', () {
    expect(bibleChapterTotal, 1361);
  });

  test('у каждой книги своё сокращение, как в ссылках Азбуки', () {
    expect(bibleBooks.map((book) => book.abbreviation).toSet(), hasLength(77));
    final byCode = {for (final book in bibleBooks) book.code: book};
    expect(byCode['Gen']!.abbreviation, 'Быт');
    expect(byCode['Mt']!.abbreviation, 'Мф');
    expect(byCode['1King']!.abbreviation, '3Цар');
    expect(byCode['pJer']!.abbreviation, 'Посл.Иер');
    expect(byCode['Apok']!.abbreviation, 'Откр');
  });
}
