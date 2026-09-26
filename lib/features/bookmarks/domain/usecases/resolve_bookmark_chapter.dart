import '../../../bible/domain/entities/bible_book.dart';
import '../entities/bookmark.dart';

typedef BookmarkChapter = ({BibleBook book, int chapter, int verse});

/// Восстанавливает главу по стабильному ID, включая уже сохранённые закладки.
/// Подпись источника не разбираем: у толкования там может быть имя автора.
class ResolveBookmarkChapter {
  const ResolveBookmarkChapter();

  static final _bible = RegExp(r'^bible-([A-Za-z0-9]+)-(\d+):(\d+)$');
  static final _dailyVerse = RegExp(
    r'^verse-([A-Za-z0-9]+)\.\d+:\d+(?:-(?:\d+:)?\d+)?-(\d+):(\d+)$',
  );
  static final _legacyVerse = RegExp(r'^verse-([A-Za-z0-9]+)\.(\d+):(\d+)$');
  static final _interpretation = RegExp(
    r'^interpretation-([А-Яа-яA-Za-z0-9]+)\.(\d+):(\d+)(?:[–—-]\d+)?$',
  );
  static const _gospels = {'Мф': 'Mt', 'Мк': 'Mk', 'Лк': 'Lk', 'Ин': 'Jn'};

  BookmarkChapter? call(Bookmark bookmark) {
    final match = switch (bookmark.kind) {
      BookmarkKind.verse || BookmarkKind.card =>
        _bible.firstMatch(bookmark.id) ??
            _dailyVerse.firstMatch(bookmark.id) ??
            _legacyVerse.firstMatch(bookmark.id),
      BookmarkKind.interpretation => _interpretation.firstMatch(bookmark.id),
      BookmarkKind.story => null,
    };
    if (match == null) return null;

    final code = _gospels[match.group(1)] ?? match.group(1);
    final book = bibleBooks.where((book) => book.code == code).firstOrNull;
    final chapter = int.tryParse(match.group(2)!);
    final verse = int.tryParse(match.group(3)!);
    if (book == null ||
        chapter == null ||
        chapter < 1 ||
        chapter > book.chapterCount ||
        verse == null ||
        verse < 1) {
      return null;
    }
    return (book: book, chapter: chapter, verse: verse);
  }
}
