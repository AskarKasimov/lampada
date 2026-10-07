import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/features/bible/domain/bible_chapter_statuses.dart';
import 'package:lampada/features/bible/domain/entities/bible_book.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/domain/repositories/bible_repository.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/screens/bible_info_screen.dart';
import 'package:lampada/features/bible/presentation/screens/bible_reader_screen.dart';
import 'package:lampada/features/bible/presentation/screens/bible_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/full_card_text_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/vertical_card_reader.dart';

class _FakeRepository implements BibleRepository {
  BibleChapterId? lastChapter;
  final cached = <BibleChapterId>{};
  final read = <BibleChapterId>{};

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async {
    cached.add((book, chapter));
    return Success(
      BibleChapter(
        book: book,
        number: chapter,
        verses: const [
          BibleVerse(number: 1, text: 'Первый стих'),
          BibleVerse(number: 2, text: 'Второй стих'),
        ],
      ),
    );
  }

  @override
  Future<Result<BibleChapterStatuses>> getChapterStatuses() async => Success((
    lastChapter: lastChapter,
    cached: {...cached},
    read: {...read},
    progress: {...progress},
  ));

  final progress = <BibleChapterId, BibleChapterProgress>{};

  @override
  Future<Result<void>> saveChapterProgress(
    String book,
    int chapter,
    BibleChapterProgress value,
  ) async {
    lastChapter = (book, chapter);
    progress[(book, chapter)] = value;
    return const Success(null);
  }

  @override
  Future<Result<void>> markChapterRead(String book, int chapter) async {
    read.add((book, chapter));
    return const Success(null);
  }
}

class _FailOnceRepository extends _FakeRepository {
  bool _failed = false;

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async {
    if (!_failed) {
      _failed = true;
      return const Failure(AppFailure('Нет сети', kind: FailureKind.network));
    }
    return super.getChapter(book, chapter);
  }
}

class _DelayedRepository extends _FakeRepository {
  final initial = Completer<Result<BibleChapter>>();

  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) =>
      book == 'Mt' ? initial.future : super.getChapter(book, chapter);
}

class _LongVerseRepository extends _FakeRepository {
  _LongVerseRepository({this.repeats = 200});
  final int repeats;
  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async =>
      Success(
        BibleChapter(
          book: book,
          number: chapter,
          verses: [BibleVerse(number: 1, text: 'Длинный стих ' * repeats)],
        ),
      );
}

class _LongChapterRepository extends _FakeRepository {
  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async =>
      Success(
        BibleChapter(
          book: book,
          number: chapter,
          verses: [
            for (var number = 1; number <= 176; number++)
              BibleVerse(number: number, text: 'Стих $number'),
          ],
        ),
      );
}

void main() {
  testWidgets('Повторить после ошибки первой главы заново загружает текст', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FailOnceRepository()),
        ],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Mt', 'От Матфея', 28),
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Не удалось открыть чтение'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Первый стих'), findsOneWidget);
  });

  testWidgets('Евангелия видны сразу в порядке Матфей, Марк, Лука, Иоанн', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: BibleScreen())),
      ),
    );
    final titles = [
      'От Матфея',
      'От Марка',
      'От Луки',
      'От Иоанна',
      'Деяния святых Апостолов',
    ];
    for (final title in titles) {
      expect(find.text(title), findsOneWidget);
    }
    for (var i = 1; i < titles.length; i++) {
      expect(
        tester.getTopLeft(find.text(titles[i])).dy,
        greaterThan(tester.getTopLeft(find.text(titles[i - 1])).dy),
      );
    }
    expect(find.text('От Матфея'), findsOneWidget);
  });

  testWidgets('список слева выбирает главу, крестик справа закрывает читалку', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Mt', 'От Матфея', 28),
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byTooltip('Книги и главы');
    expect(list, findsOneWidget);
    expect(tester.getCenter(list).dx, lessThan(400));
    final close = find.byTooltip('Закрыть');
    expect(tester.getCenter(close).dx, greaterThan(400));
    expect(find.byIcon(CupertinoIcons.arrow_left), findsNothing);
    expect(tester.getCenter(list).dy, lessThan(60));
    await tester.tap(list);
    await tester.pumpAndSettle();
    await tester.tap(find.text('От Марка'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bible-chapter-Mk-3')));
    await tester.pumpAndSettle();
    expect(find.text('От Марка'), findsOneWidget);
    expect(find.text('3:1'), findsOneWidget);
    expect(find.byType(BibleScreen), findsNothing);
  });

  testWidgets('во вкладке выбор книги справа сверху с названием и главой', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Mt', 'От Матфея', 28),
            chapter: 1,
            showClose: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byTooltip('Книги и главы');
    expect(list, findsOneWidget);
    expect(tester.getCenter(list).dx, greaterThan(600));
    expect(tester.getCenter(list).dy, lessThan(60));
    expect(
      find.descendant(of: list, matching: find.text('От Матфея')),
      findsOneWidget,
    );
    // Название книги уже в капсуле: отдельной подписи по центру нет.
    expect(find.text('От Матфея'), findsOneWidget);
    expect(find.descendant(of: list, matching: find.text('1')), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.list_bullet), findsNothing);
    expect(find.byIcon(CupertinoIcons.arrow_left), findsNothing);
    await tester.tap(list);
    await tester.pumpAndSettle();
    expect(find.byType(BibleScreen), findsOneWidget);
  });

  testWidgets('выбор главы во время загрузки отменяет устаревший результат', (
    tester,
  ) async {
    final repository = _DelayedRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bibleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Mt', 'От Матфея', 28),
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Книги и главы'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('От Марка'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('bible-chapter-Mk-3')));
    await tester.pumpAndSettle();
    repository.initial.complete(
      const Success(
        BibleChapter(
          book: 'Mt',
          number: 1,
          verses: [BibleVerse(number: 1, text: 'Отложенный стих')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3:1'), findsOneWidget);
    expect(
      tester
          .widget<VerticalCardReader>(find.byType(VerticalCardReader))
          .itemCount,
      3,
    );
    expect(tester.takeException(), isNull);
  });

  for (final colors in [AppColorsExtension.light, AppColorsExtension.dark]) {
    testWidgets(
      'плитка показывает прогресс и продолжает чтение: ${colors.background}',
      (tester) async {
        final repository = _LongChapterRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [bibleRepositoryProvider.overrideWithValue(repository)],
            child: MaterialApp(
              theme: ThemeData(extensions: [colors]),
              home: const Scaffold(body: BibleScreen()),
            ),
          ),
        );
        await tester.tap(find.text('Иакова'));
        await tester.pumpAndSettle();
        final tile = find.byKey(const ValueKey('bible-chapter-Jac-1'));
        await tester.tap(tile);
        await tester.pumpAndSettle();
        tester
            .widget<VerticalCardReader>(find.byType(VerticalCardReader))
            .controller
            .jumpToPage(30);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(CupertinoIcons.xmark));
        await tester.pumpAndSettle();
        final fill = find.byKey(const ValueKey('bible-progress-Jac-1'));
        expect(fill, findsOneWidget);
        expect(
          tester.getSize(fill).width / tester.getSize(tile).width,
          closeTo(31 / 176, 0.001),
        );
        final fillColor =
            (tester.widget<Ink>(fill).decoration! as BoxDecoration).color!;
        expect(fillColor.a, lessThan(0.3));
        final text = tester.widget<Text>(
          find.descendant(of: tile, matching: find.text('1')),
        );
        final background = Color.alphaBlend(fillColor, colors.background);
        final a = text.style!.color!.computeLuminance();
        final b = background.computeLuminance();
        expect(
          (a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05)),
          greaterThanOrEqualTo(4.5),
        );
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(find.text('1:31'), findsOneWidget);
        await tester.drag(find.byType(PageView), const Offset(0, 500));
        await tester.pumpAndSettle();
        expect(find.text('1:30'), findsOneWidget);
      },
    );
  }

  testWidgets('заголовок Завета визуально крупнее названия книги', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: BibleScreen())),
      ),
    );

    expect(
      tester.getSize(find.text('Новый Завет')).height,
      greaterThan(tester.getSize(find.text('Иакова')).height),
    );
  });

  for (final reduceMotion in [false, true]) {
    testWidgets('книга раскрывает главы плавно, Reduce Motion: $reduceMotion', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 6000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: const Scaffold(body: BibleScreen()),
            ),
          ),
        ),
      );
      final nextBook = find.text('Иакова');
      final before = tester.getTopLeft(nextBook).dy;
      await tester.tap(find.text('Деяния святых Апостолов'));
      await tester.pump();
      if (!reduceMotion) {
        expect(tester.getTopLeft(nextBook).dy, closeTo(before, 1));
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.getTopLeft(nextBook).dy, greaterThan(before));
      }
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(nextBook).dy, greaterThan(before));
      await tester.tap(find.text('Деяния святых Апостолов'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(nextBook).dy, closeTo(before, 1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('заголовок текущего завета закреплён под AppBar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: BibleScreen())),
      ),
    );
    final newHeader = find.text('Новый Завет');
    final initialY = tester.getTopLeft(newHeader).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(newHeader).dy, closeTo(initialY, 1));
    await tester.scrollUntilVisible(find.text('Ветхий Завет'), 300);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Ветхий Завет')).dy,
      closeTo(initialY, 1),
    );
    expect(newHeader.hitTestable(), findsNothing);
  });

  testWidgets('оба завета всегда раскрыты, заголовки не имеют кнопок', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 6000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: BibleScreen())),
      ),
    );
    expect(find.text('От Матфея'), findsOneWidget);
    expect(find.text('Аввакума'), findsOneWidget);
    for (final title in ['Новый Завет', 'Ветхий Завет']) {
      expect(
        find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
        findsNothing,
      );
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }
    expect(find.text('От Матфея'), findsOneWidget);
    expect(find.text('Аввакума'), findsOneWidget);
    expect(
      tester.widget<SliverAppBar>(find.byType(SliverAppBar)).pinned,
      isTrue,
    );
  });

  testWidgets('кнопка справки открывает пояснение статусов глав', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: BibleScreen())),
      ),
    );

    await tester.tap(find.byTooltip('Помощь'));
    await tester.pumpAndSettle();

    expect(find.byType(BibleInfoScreen), findsOneWidget);
    expect(find.text('Русский Синодальный перевод'), findsOneWidget);
    expect(find.text('Прочитанная глава'), findsOneWidget);
    expect(find.text('Доступна офлайн'), findsOneWidget);
  });

  testWidgets('скачанная глава имеет рамку, прочитанная — заливку', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bibleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: BibleScreen())),
      ),
    );
    await tester.scrollUntilVisible(find.text('От Иоанна'), 300);
    await tester.ensureVisible(find.text('От Иоанна'));
    await tester.tap(find.text('От Иоанна'));
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('bible-chapter-Jn-3'));
    final colors = AppColorsExtension.of(tester.element(tile));

    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    Navigator.of(tester.element(find.byType(BibleReaderScreen))).pop();
    await tester.pumpAndSettle();
    final cachedTile = tester.widget<Material>(tile);
    expect(cachedTile.color, colors.background);
    expect(
      (cachedTile.shape! as RoundedRectangleBorder).side.color,
      colors.accent,
    );
    expect(
      tester
          .widget<Text>(find.descendant(of: tile, matching: find.text('3')))
          .style!
          .color,
      colors.ink,
    );

    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    Navigator.of(tester.element(find.byType(BibleReaderScreen))).pop();
    await tester.pumpAndSettle();
    final readTile = tester.widget<Material>(tile);
    expect(readTile.color, colors.accent);
    expect((readTile.shape! as RoundedRectangleBorder).side, BorderSide.none);
    expect(
      tester
          .widget<Text>(find.descendant(of: tile, matching: find.text('3')))
          .style!
          .color,
      colors.background,
    );
  });

  testWidgets('список книг показывает Новый Завет перед Ветхим', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: BibleScreen())),
      ),
    );

    expect(find.text('Новый Завет'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Петра 2-е'), 300);
    expect(find.text('Петра 2-е'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ветхий Завет'), 300);
    await tester.tap(find.text('Ветхий Завет'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ветхий Завет'), -300);
    expect(find.text('Ветхий Завет'), findsOneWidget);
    expect(find.text('Аввакума'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Аввакума'), -300);
    expect(find.text('Аввакума'), findsOneWidget);
  });

  testWidgets(
    'книга раскрывает главы, выбранная глава начинается с первого стиха',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
          ],
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: const Scaffold(body: BibleScreen()),
          ),
        ),
      );

      await tester.scrollUntilVisible(find.text('От Иоанна'), 300);
      await tester.ensureVisible(find.text('От Иоанна'));
      await tester.tap(find.text('От Иоанна'));
      await tester.pumpAndSettle();
      expect(find.text('Глава'), findsOneWidget);
      expect(find.text('Стих'), findsNothing);
      await tester.tap(find.text('3').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final reader = find.byType(BibleReaderScreen);
      expect(ModalRoute.of(tester.element(reader))!.fullscreenDialog, isTrue);
      final openingPosition = tester.getTopLeft(reader);
      expect(openingPosition.dx, closeTo(0, 1));
      expect(openingPosition.dy, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(reader, findsOneWidget);
      expect(find.text('Первый стих'), findsOneWidget);
      expect(find.text('Стих'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(VerticalCardReader),
          matching: find.text('От Иоанна'),
        ),
        findsOneWidget,
      );
      expect(find.text('3:1'), findsOneWidget);
      expect(find.text('— 3:1'), findsNothing);
      expect(find.text('От Иоанна 3:1'), findsNothing);
      expect(tester.widget<ProgressDots>(find.byType(ProgressDots)).count, 2);
      final back = find.byIcon(CupertinoIcons.xmark);
      expect(back, findsOneWidget);
      expect(
        tester.getCenter(back).dx,
        greaterThan(tester.getSize(reader).width / 2),
      );
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(BibleReaderScreen), findsNothing);
      expect(find.byType(BibleScreen), findsOneWidget);
    },
  );

  testWidgets('свайп от последнего стиха открывает начало следующей главы', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bibleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Jn', 'От Иоанна', 21),
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Первый стих'), findsOneWidget);
    expect(repository.cached, {('Jn', 1)});

    expect(
      tester.widget<PageView>(find.byType(PageView)).scrollDirection,
      Axis.vertical,
    );
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Второй стих'), findsOneWidget);
    expect(repository.cached, {('Jn', 1)});
    expect(
      tester.widget<ProgressDots>(find.byType(ProgressDots)).currentIndex,
      1,
    );
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Первый стих'), findsOneWidget);
    expect(find.text('2:1'), findsOneWidget);
    expect(repository.cached, {('Jn', 1), ('Jn', 2)});
    expect(
      tester.widget<ProgressDots>(find.byType(ProgressDots)).currentIndex,
      0,
    );
  });

  testWidgets('Библия показывает вмещающийся длинный стих без раскрытия', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(
            _LongVerseRepository(repeats: 20),
          ),
        ],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Apok', 'Откровение', 1),
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Длинный стих ' * 20), findsOneWidget);
    expect(find.byTooltip('Открыть полный текст'), findsNothing);
  });

  testWidgets('длинный стих открывается целиком из карточки', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_LongVerseRepository()),
        ],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Apok', 'Откровение', 1),
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Открыть полный текст'), findsOneWidget);
    await tester.tap(find.byTooltip('Открыть полный текст'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FullCardTextScreen), findsOneWidget);
    expect(find.text('Длинный стих ' * 200), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FullCardTextScreen),
        matching: find.text('1:1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('все точки длинной главы доступны без многоточий', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_LongChapterRepository()),
        ],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Apok', 'Откровение', 1),
            chapter: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.widget<ProgressDots>(find.byType(ProgressDots)).count, 176);
    expect(find.text('⋮'), findsNothing);
    tester
        .widget<VerticalCardReader>(find.byType(VerticalCardReader))
        .controller
        .jumpToPage(30);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1:31'), findsOneWidget);
    expect(
      tester.widget<ProgressDots>(find.byType(ProgressDots)).currentIndex,
      30,
    );
    final railScroll = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(VerticalCardReader),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(railScroll.controller!.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
