import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bookmarks/data/repositories/prefs_bookmarks_repository.dart';
import 'package:lampada/features/bookmarks/domain/entities/bookmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

Bookmark _bookmark(
  String id, {
  String text = 'ТЕКСТ',
  DateTime? savedAt,
  BookmarkKind kind = BookmarkKind.card,
}) =>
    Bookmark(
      id: id,
      kind: kind,
      text: text,
      source: 'Источник',
      label: 'Цитата дня',
      savedAt: savedAt ?? DateTime(2026, 7, 28, 10),
    );

List<Bookmark> _value(Result<List<Bookmark>> r) =>
    (r as Success<List<Bookmark>>).value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrefsBookmarksRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = PrefsBookmarksRepository(await SharedPreferences.getInstance());
  });

  test('пустая копилка — пустой список, а не сбой', () async {
    expect(_value(await repo.load()), isEmpty);
  });

  test('сохранённое переживает пересоздание репозитория', () async {
    // FR-017: копилка локальная и должна лежать в prefs, а не в памяти.
    await repo.save(_bookmark('quote-2026-07-28'));

    final reopened =
        PrefsBookmarksRepository(await SharedPreferences.getInstance());
    expect(_value(await reopened.load()).single.id, 'quote-2026-07-28');
  });

  test('поля записи не теряются при сериализации', () async {
    await repo.save(
      _bookmark('verse-Jn.10:1', kind: BookmarkKind.verse, text: 'Я есмь дверь'),
    );

    final saved = _value(await repo.load()).single;
    expect(saved.kind, BookmarkKind.verse);
    expect(saved.text, 'Я есмь дверь');
    expect(saved.source, 'Источник');
    expect(saved.label, 'Цитата дня');
    expect(saved.savedAt, DateTime(2026, 7, 28, 10));
  });

  test('свежие сверху', () async {
    await repo.save(_bookmark('старая', savedAt: DateTime(2026, 7, 20)));
    await repo.save(_bookmark('новая', savedAt: DateTime(2026, 7, 28)));

    expect(_value(await repo.load()).map((b) => b.id), ['новая', 'старая']);
  });

  test('повторное сохранение того же id не двоит запись', () async {
    await repo.save(_bookmark('quote', text: 'ПЕРВЫЙ'));
    final after = _value(await repo.save(_bookmark('quote', text: 'ВТОРОЙ')));

    expect(after, hasLength(1));
    expect(after.single.text, 'ВТОРОЙ');
  });

  test('удаление убирает только свою запись', () async {
    await repo.save(_bookmark('a'));
    await repo.save(_bookmark('b'));

    expect(_value(await repo.remove('a')).map((b) => b.id), ['b']);
  });

  test('удаление несуществующего id — не сбой', () async {
    await repo.save(_bookmark('a'));

    expect(_value(await repo.remove('нет такого')).map((b) => b.id), ['a']);
  });

  test('битый JSON в prefs отдаёт Failure, а не роняет приложение', () async {
    SharedPreferences.setMockInitialValues({'bookmarks': 'не json'});
    final broken =
        PrefsBookmarksRepository(await SharedPreferences.getInstance());

    expect(await broken.load(), isA<Failure<List<Bookmark>>>());
  });
}
