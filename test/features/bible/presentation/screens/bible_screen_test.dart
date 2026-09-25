import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/bible/domain/entities/bible_book.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/domain/repositories/bible_repository.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/screens/bible_reader_screen.dart';
import 'package:lampada/features/bible/presentation/screens/bible_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/full_card_text_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/vertical_card_reader.dart';

class _FakeRepository implements BibleRepository {
  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async =>
      Success(
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

class _LongVerseRepository implements BibleRepository {
  @override
  Future<Result<BibleChapter>> getChapter(String book, int chapter) async =>
      Success(
        BibleChapter(
          book: book,
          number: chapter,
          verses: [BibleVerse(number: 1, text: 'Длинный стих ' * 20)],
        ),
      );
}

class _LongChapterRepository implements BibleRepository {
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
  testWidgets(
    'книга раскрывает главы, выбранная глава начинается с первого стиха',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
          ],
          child: const MaterialApp(home: Scaffold(body: BibleScreen())),
        ),
      );

      await tester.scrollUntilVisible(find.text('От Иоанна'), 300);
      await tester.tap(find.text('От Иоанна'));
      await tester.pump();
      expect(find.text('Глава'), findsOneWidget);
      expect(find.text('Стих'), findsNothing);
      await tester.tap(find.text('3').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(BibleReaderScreen), findsOneWidget);
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
    },
  );

  testWidgets('свайп от последнего стиха открывает начало следующей главы', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
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

    expect(
      tester.widget<PageView>(find.byType(PageView)).scrollDirection,
      Axis.vertical,
    );
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Второй стих'), findsOneWidget);
    expect(
      tester.widget<ProgressDots>(find.byType(ProgressDots)).currentIndex,
      1,
    );
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Первый стих'), findsOneWidget);
    expect(find.text('2:1'), findsOneWidget);
    expect(
      tester.widget<ProgressDots>(find.byType(ProgressDots)).currentIndex,
      0,
    );
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
    expect(find.text('Длинный стих ' * 20), findsOneWidget);
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
