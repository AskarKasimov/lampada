import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lampada/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:lampada/features/bookmarks/presentation/providers/providers.dart';
import 'package:lampada/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:lampada/features/bookmarks/presentation/widgets/bookmark_button.dart';
import 'package:lampada/features/bookmarks/presentation/widgets/bookmarks_empty_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/shared_preferences_stores.dart';

Bookmark _bookmark(String id, {String text = 'Сохранённая мысль'}) => Bookmark(
  id: id,
  kind: BookmarkKind.card,
  text: text,
  source: 'Иоанн Лествичник',
  label: 'Цитата дня',
  savedAt: DateTime(2026, 7, 28),
);

class _FailingRemoveRepository implements BookmarksRepository {
  @override
  Future<Result<List<Bookmark>>> load() async =>
      Success([_bookmark('quote-1')]);

  @override
  Future<Result<List<Bookmark>>> remove(String id) async =>
      const Failure(AppFailure('Ошибка', kind: FailureKind.unknown));

  @override
  Future<Result<List<Bookmark>>> save(Bookmark bookmark) async =>
      Success([bookmark]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrap(Widget child) => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('пустая копилка — тёплое состояние без назидания', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const BookmarksScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(BookmarksEmptyView), findsOneWidget);
    expect(find.text('Копилка смыслов пока пуста'), findsOneWidget);
  });

  testWidgets('сохранённое видно в списке текстом-героем', (tester) async {
    await tester.pumpWidget(wrap(const BookmarksScreen()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BookmarksScreen)),
    );
    await container
        .read(bookmarksProvider.notifier)
        .toggle(_bookmark('quote-1'));
    await tester.pumpAndSettle();

    expect(find.byType(BookmarksEmptyView), findsNothing);
    expect(find.text('Сохранённая мысль'), findsOneWidget);
  });

  testWidgets('удаление убирает запись из списка', (tester) async {
    await tester.pumpWidget(wrap(const BookmarksScreen()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BookmarksScreen)),
    );
    final notifier = container.read(bookmarksProvider.notifier);
    await notifier.toggle(_bookmark('quote-1'));
    await tester.pumpAndSettle();

    await notifier.remove('quote-1');
    await tester.pumpAndSettle();

    expect(find.byType(BookmarksEmptyView), findsOneWidget);
  });

  testWidgets('ошибка удаления оставляет закладку в списке', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          bookmarksRepositoryProvider.overrideWithValue(
            _FailingRemoveRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: BookmarksScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('quote-1')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сохранённая мысль'), findsOneWidget);
    expect(find.text('Не удалось удалить закладку'), findsOneWidget);
  });

  group('кнопка сохранения', () {
    testWidgets('переключает состояние и подтверждает сохранение', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(BookmarkButton(bookmark: _bookmark('q'))));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);

      await tester.tap(find.byType(BookmarkButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.bookmark_fill), findsOneWidget);
      // FR-016: подтверждение обязательно — смена иконки проходит мимо глаз.
      expect(find.text('Сохранено в копилку'), findsOneWidget);
    });

    testWidgets('повторный тап снимает закладку', (tester) async {
      await tester.pumpWidget(wrap(BookmarkButton(bookmark: _bookmark('q'))));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BookmarkButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BookmarkButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BookmarkButton)),
      );
      expect(container.read(bookmarksProvider).value, isEmpty);
    });

    testWidgets('не подтверждает сохранение, если запись не удалась', (
      tester,
    ) async {
      SharedPreferences.resetStatic();
      installSharedPreferencesStore(RejectingWriteStore());
      final failingPrefs = await SharedPreferences.getInstance();
      addTearDown(() => SharedPreferences.setMockInitialValues({}));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(failingPrefs),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: BookmarkButton(bookmark: _bookmark('q'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BookmarkButton));
      await tester.pumpAndSettle();

      expect(find.text('Сохранено в копилку'), findsNothing);
      expect(find.text('Не удалось сохранить закладку'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);
    });

    testWidgets('момент сохранения ставится при нажатии, а не при сборке', (
      tester,
    ) async {
      // В карточку кладётся заглушка epoch — иначе список сортировался бы
      // по времени отрисовки.
      await tester.pumpWidget(wrap(BookmarkButton(bookmark: _bookmark('q'))));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BookmarkButton));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BookmarkButton)),
      );
      final saved = container.read(bookmarksProvider).value!.single;
      expect(saved.savedAt.year, greaterThan(2020));
    });
  });
}
