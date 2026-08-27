import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lampada/features/bookmarks/presentation/providers/providers.dart';
import 'package:lampada/features/bookmarks/presentation/screens/bookmark_detail_screen.dart';
import 'package:lampada/features/bookmarks/presentation/widgets/bookmark_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _bookmark = Bookmark(
  id: 'interpretation-1',
  kind: BookmarkKind.interpretation,
  text: 'Полный текст толкования, длинный и без сокращений.',
  source: 'Феофилакт Болгарский, блж.',
  label: 'Толкование',
  savedAt: DateTime(2026, 7, 28),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    // Экран открывают из списка уже сохранённой записи — сеем её заранее,
    // а не заводим отдельную заглушку копилки.
    SharedPreferences.setMockInitialValues({
      'flutter.bookmarks':
          '[{'
          '"id":"interpretation-1","kind":"interpretation",'
          '"text":"Полный текст толкования, длинный и без сокращений.",'
          '"source":"Феофилакт Болгарский, блж.","label":"Толкование",'
          '"savedAt":"2026-07-28T00:00:00.000"}]',
    });
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrap(Widget child) => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(wrap(BookmarkDetailScreen(bookmark: _bookmark)));
    // bookmarksProvider читает SharedPreferences асинхронно — без этого
    // кадра BookmarkButton успевает отрисоваться раньше, чем узнаёт,
    // что запись уже сохранена.
    await tester.pumpAndSettle();
  }

  testWidgets('показывает весь текст, источник, подпись и дату', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(_bookmark.text), findsOneWidget);
    expect(find.text('— ${_bookmark.source}'), findsOneWidget);
    expect(find.text('Толкование'), findsOneWidget);
    expect(find.text('28 июля'), findsOneWidget);
  });

  testWidgets(
    'кнопка закладки стоит заполненной — сюда попадают уже сохранённые',
    (tester) async {
      await pump(tester);

      expect(find.byIcon(CupertinoIcons.bookmark_fill), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.bookmark), findsNothing);
    },
  );

  testWidgets(
    'повторный тап по кнопке снимает закладку, а экран остаётся открытым',
    (tester) async {
      await pump(tester);

      await tester.tap(find.byType(BookmarkButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.bookmark), findsOneWidget);
      // Текст никуда не пропадает — снялась только закладка.
      expect(find.text(_bookmark.text), findsOneWidget);
      expect(find.byType(BookmarkDetailScreen), findsOneWidget);
    },
  );

  testWidgets('снятая закладка не возвращается в список копилки', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(BookmarkButton));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BookmarkDetailScreen)),
    );
    expect(container.read(bookmarksProvider).value, isEmpty);
  });

  testWidgets('крестик закрывает экран', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BookmarkDetailScreen(bookmark: _bookmark),
                  ),
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.byType(BookmarkDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(BookmarkDetailScreen), findsNothing);
  });

  testWidgets('быстрый свайп вниз закрывает экран', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BookmarkDetailScreen(bookmark: _bookmark),
                  ),
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(BookmarkDetailScreen),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(BookmarkDetailScreen), findsNothing);
  });
}
