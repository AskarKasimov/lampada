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

void main() {
  testWidgets('книга раскрывает главы, глава — стихи и ридер', (tester) async {
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
    await tester.tap(find.text('3').first);
    await tester.pump();
    await tester.pump();
    expect(find.text('Стих'), findsOneWidget);
    await tester.tap(find.text('2').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BibleReaderScreen), findsOneWidget);
    expect(find.text('Второй стих'), findsOneWidget);
  });

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
            chapter: 3,
            verse: 2,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Второй стих'), findsOneWidget);

    expect(
      tester.widget<PageView>(find.byType(PageView)).scrollDirection,
      Axis.vertical,
    );
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Первый стих'), findsOneWidget);
    expect(find.text('От Иоанна 4:1'), findsOneWidget);
  });

  testWidgets('длинный стих открывается целиком из карточки', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(_LongVerseRepository()),
        ],
        child: const MaterialApp(
          home: BibleReaderScreen(
            book: BibleBook('Apok', 'Откровение', 22),
            chapter: 22,
            verse: 1,
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
  });
}
