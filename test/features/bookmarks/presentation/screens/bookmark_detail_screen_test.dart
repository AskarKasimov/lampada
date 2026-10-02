import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/app_pill_badge.dart';
import 'package:lampada/core/widgets/app_share_button.dart';
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
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text(verse.text), findsOneWidget);
  });

  testWidgets('запись без библейской ссылки не предлагает главу', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byTooltip('Открыть главу'), findsNothing);
  });

  testWidgets('крестик сверху справа, закладка и отправка снизу справа', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(BackButton), findsNothing);
    final close = find.byIcon(CupertinoIcons.xmark);
    final bookmark = find.byType(BookmarkButton);
    final share = find.byType(AppShareButton);
    final size = tester.getSize(find.byType(BookmarkDetailScreen));
    expect(tester.getCenter(close).dx, greaterThan(size.width / 2));
    expect(tester.getCenter(close).dy, lessThan(size.height / 2));
    expect(tester.getCenter(bookmark).dx, greaterThan(size.width / 2));
    expect(tester.getCenter(bookmark).dy, greaterThan(size.height / 2));
    expect(tester.getCenter(share).dx, tester.getCenter(bookmark).dx);
    expect(
      tester.getCenter(share).dy,
      greaterThan(tester.getCenter(bookmark).dy),
    );
    expect(tester.getSize(bookmark), const Size(56, 56));
    expect(tester.getSize(share), const Size(56, 56));
    expect(
      tester.widget<AppShareButton>(share).text,
      '${_bookmark.text}\n\n— ${_bookmark.source}',
    );
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

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();

    expect(find.byType(BookmarkDetailScreen), findsNothing);
  });

  for (final dx in [-180.0, 180.0, 80.0, 0.0]) {
    testWidgets(
      'жест ($dx) закрывает только после длинного горизонтального свайпа',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BookmarkDetailScreen(bookmark: _bookmark),
                  ),
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Открыть'));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(BookmarkDetailScreen),
          Offset(dx, dx == 0 ? 180 : 0),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(BookmarkDetailScreen),
          dx.abs() >= 112 ? findsNothing : findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'экран движется по фиксированной дуге независимо от вертикали жеста',
    (tester) async {
      await pump(tester);
      final origin = tester.getTopLeft(find.byType(Scaffold));
      final gesture = await tester.startGesture(const Offset(400, 300));
      await gesture.moveBy(const Offset(80, 30));
      await tester.pump();
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final translation = transforms.first.transform.getTranslation();
      expect(translation.x, 80);
      expect(translation.y, 2); // 80² / (800 × 4), как у fullscreen.
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(Scaffold)), origin);
    },
  );
}
