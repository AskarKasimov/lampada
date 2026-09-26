import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lampada/features/bookmarks/domain/usecases/resolve_bookmark_chapter.dart';

void main() {
  const resolve = ResolveBookmarkChapter();
  Bookmark bookmark(String id, BookmarkKind kind) => Bookmark(
    id: id,
    kind: kind,
    text: 'Сохранённый текст',
    source: 'Источник',
    label: 'Закладка',
    savedAt: DateTime(2026),
  );

  for (final (id, kind, code, chapter, verse) in [
    ('bible-Jn-10:2', BookmarkKind.verse, 'Jn', 10, 2),
    ('bible-1Cor-13:4', BookmarkKind.verse, '1Cor', 13, 4),
    ('verse-Jn.10:1-9-10:2', BookmarkKind.card, 'Jn', 10, 2),
    ('verse-Mt.16:20-17:9-17:1', BookmarkKind.card, 'Mt', 17, 1),
    ('verse-Jn.10:2', BookmarkKind.verse, 'Jn', 10, 2),
    ('interpretation-Ин.10:1–3', BookmarkKind.interpretation, 'Jn', 10, 1),
    ('interpretation-Мф.20:1–7', BookmarkKind.interpretation, 'Mt', 20, 1),
    ('interpretation-Мк.1:1', BookmarkKind.interpretation, 'Mk', 1, 1),
    ('interpretation-Лк.2:1', BookmarkKind.interpretation, 'Lk', 2, 1),
  ]) {
    test('определяет главу старой закладки $id', () {
      final target = resolve(bookmark(id, kind));
      expect(target?.book.code, code);
      expect(target?.chapter, chapter);
      expect(target, (book: target!.book, chapter: chapter, verse: verse));
    });
  }

  for (final (id, kind) in [
    ('quote-2026-07-28', BookmarkKind.card),
    ('interpretation-null', BookmarkKind.interpretation),
    ('bible-Unknown-1:1', BookmarkKind.verse),
    ('bible-Jn-0:1', BookmarkKind.verse),
    ('bible-Jn-22:1', BookmarkKind.verse),
    ('bible-Jn-10:0', BookmarkKind.verse),
    ('verse-Jn.10:1-9-broken', BookmarkKind.card),
    ('interpretation-1', BookmarkKind.interpretation),
    ('bible-Jn-10:1', BookmarkKind.story),
  ]) {
    test('не угадывает главу неподходящей закладки $id ($kind)', () {
      expect(resolve(bookmark(id, kind)), isNull);
    });
  }
}
