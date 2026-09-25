import '../../domain/entities/bible_chapter.dart';
import '../dto/bible_chapter_dto.dart';

extension BibleChapterMapper on BibleChapterDto {
  BibleChapter toEntity() => BibleChapter(
    book: book,
    number: number,
    verses: [
      for (final verse in verses)
        BibleVerse(number: verse.number, text: verse.text),
    ],
  );
}
