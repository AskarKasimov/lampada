import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/app_pill_badge.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/screens/bible_reader_screen.dart';
import 'package:lampada/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lampada/features/bookmarks/presentation/providers/providers.dart';
import 'package:lampada/features/bookmarks/presentation/screens/bookmark_detail_screen.dart';
import 'package:lampada/features/bookmarks/presentation/widgets/bookmark_button.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/theme/card_type_style.dart';
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
  late List<(String, int)> requestedChapters;

  setUp(() async {
    requestedChapters = [];
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
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      bibleChapterProvider.overrideWith((ref, key) async {
        requestedChapters.add(key);
        return BibleChapter(
          book: key.$1,
          number: key.$2,
          verses: const [
            BibleVerse(number: 1, text: 'Первый стих полной главы'),
            BibleVerse(number: 2, text: 'Второй стих полной главы'),
            BibleVerse(number: 3, text: 'Последний стих полной главы'),
          ],
        );
      }),
    ],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(wrap(BookmarkDetailScreen(bookmark: _bookmark)));
    // bookmarksProvider читает SharedPreferences асинхронно — без этого
    // кадра BookmarkButton успевает отрисоваться раньше, чем узнаёт,
    // что запись уже сохранена.
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    for (final type in CardType.values) {
      testWidgets('чип $type в навбаре с цветом карточки ($brightness)', (
        tester,
      ) async {
        final style = type.styleFor(brightness);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: brightness == Brightness.dark
                  ? AppTheme.dark
                  : AppTheme.light,
              home: BookmarkDetailScreen(
                bookmark: _bookmark.copyWith(
                  kind: BookmarkKind.card,
                  label: style.label,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final badge = find.byType(AppPillBadge);
        expect(
          find.descendant(of: find.byType(AppBar), matching: badge),
          findsOneWidget,
        );
        final widget = tester.widget<AppPillBadge>(badge);
        expect(widget.background, style.tagBackground);
        expect(widget.foreground, style.tagForeground);
        expect(widget.border, isNull);
        expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
      });
    }
  }

  testWidgets('сохранённый стих предлагает открыть главу из AppBar', (
    tester,
  ) async {
    final verse = _bookmark.copyWith(
      id: 'bible-Jn-10:2',
      kind: BookmarkKind.verse,
      source: 'От Иоанна 10:2',
    );
    await tester.pumpWidget(wrap(BookmarkDetailScreen(bookmark: verse)));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Открыть главу'),
      ),
      findsOneWidget,
    );
    expect(requestedChapters, isEmpty);
    await tester.tap(find.byTooltip('Открыть главу'));
    await tester.pumpAndSettle();
    expect(requestedChapters, [('Jn', 10)]);
    expect(find.byType(BibleReaderScreen), findsOneWidget);
    expect(find.text('Второй стих полной главы').hitTestable(), findsOneWidget);
    final pages = find.byType(PageView);
    await tester.drag(pages, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Первый стих полной главы').hitTestable(), findsOneWidget);
    await tester.drag(pages, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.drag(pages, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(
      find.text('Последний стих полной главы').hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await tester.pumpAndSettle();
    expect(find.text(verse.text), findsOneWidget);
  });

  testWidgets('запись без библейской ссылки не предлагает главу', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byTooltip('Открыть главу'), findsNothing);
  });

  testWidgets('стрелка назад слева, кнопка закладки справа', (tester) async {
    await pump(tester);
    final back = find.byType(BackButton);
    final bookmark = find.byType(BookmarkButton);
    expect(back, findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark), findsNothing);
    final width = tester.getSize(find.byType(BookmarkDetailScreen)).width;
    expect(tester.getCenter(back).dx, lessThan(width / 2));
    expect(tester.getCenter(bookmark).dx, greaterThan(width / 2));
  });

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

  testWidgets('стрелка назад закрывает экран', (tester) async {
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

    await tester.tap(find.byType(BackButton));
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
