import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lampada/features/bookmarks/presentation/screens/bookmark_detail_screen.dart';
import 'package:lampada/features/bookmarks/presentation/widgets/bookmark_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _longText =
    'Толкование на несколько абзацев. ${'Оно длинное. ' * 40}Конец.';

Bookmark _bookmark({String text = 'Короткая мысль'}) => Bookmark(
  id: 'q-1',
  kind: BookmarkKind.card,
  text: text,
  source: 'Источник',
  label: 'Цитата дня',
  savedAt: DateTime(2026, 7, 28),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // BookmarkDetailScreen несёт BookmarkButton — тому нужен ProviderScope
  // с прогнозируемым хранилищем, даже когда тест не про сохранение как
  // таковое.
  Widget wrap(Widget child) => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('длинный текст в списке ограничен строками, а не показан весь', (
    tester,
  ) async {
    // Раньше сюда попадал весь текст без ограничения — толкование на
    // несколько абзацев растягивало список так, что смотреть его было
    // невозможно.
    await tester.pumpWidget(
      wrap(
        BookmarkTile(
          bookmark: _bookmark(text: _longText),
          onRemove: () async => true,
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(_longText));
    expect(text.maxLines, isNotNull);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('тап открывает полный текст на весь экран', (tester) async {
    await tester.pumpWidget(
      wrap(
        BookmarkTile(
          bookmark: _bookmark(text: _longText),
          onRemove: () async => true,
        ),
      ),
    );

    await tester.tap(find.byType(BookmarkTile));
    await tester.pumpAndSettle();

    expect(find.byType(BookmarkDetailScreen), findsOneWidget);
    // На полном экране текст не обрезан.
    final full = tester.widget<Text>(find.text(_longText));
    expect(full.maxLines, isNull);
  });

  testWidgets('свайп всё ещё удаляет запись', (tester) async {
    var removed = false;
    await tester.pumpWidget(
      wrap(
        BookmarkTile(
          bookmark: _bookmark(),
          onRemove: () async {
            removed = true;
            return true;
          },
        ),
      ),
    );

    await tester.drag(find.byType(BookmarkTile), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(removed, isTrue);
  });
}
