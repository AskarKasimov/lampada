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
}
