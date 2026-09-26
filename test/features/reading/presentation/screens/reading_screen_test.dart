import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/screens/bible_reader_screen.dart';
import 'package:lampada/features/bookmarks/presentation/widgets/bookmark_button.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:lampada/features/reading/presentation/screens/reading_screen.dart';
import 'package:lampada/features/reading/presentation/widgets/verse_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> open(
    WidgetTester tester, {
    required bool crossesChapter,
    bool recordRead = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith(
            (ref, reference) async => DailyReading(
              label: crossesChapter ? 'Ин.10:2–11:1' : 'Ин.10:2–3',
              verses: [
                const Verse(
                  number: 2,
                  chapter: 10,
                  text: 'Дневной стих',
                  interpretation: 'Объяснение стиха',
                ),
                const Verse(number: 3, chapter: 10, text: 'Конец главы'),
                if (crossesChapter)
                  const Verse(number: 1, chapter: 11, text: 'Конец отрывка'),
              ],
            ),
          ),
          bibleChapterProvider.overrideWith(
            (ref, key) async => BibleChapter(
              book: key.$1,
              number: key.$2,
              verses: [
                for (
                  var i = 1;
                  i <= (key.$2 == 10 && crossesChapter ? 3 : 4);
                  i++
                )
                  BibleVerse(number: i, text: '${key.$1} ${key.$2}:$i'),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ReadingScreen(
            reference: crossesChapter ? 'Jn.10:2-11:1' : 'Jn.10:2-3',
            date: DateTime(2026, 9, 26),
            recordProgress: false,
            recordRead: recordRead,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  const ending = 'Хотите прочесть главу полностью?';

  testWidgets(
    'сохраняет дневные стихи и толкование, в конце предлагает полную главу с первого стиха',
    (tester) async {
      await open(tester, crossesChapter: false);
      expect(find.text('Дневной стих').hitTestable(), findsOneWidget);
      expect(find.byType(BibleReaderScreen), findsNothing);
      await tester.tap(find.byType(VerseInterpretationButton));
      await tester.pumpAndSettle();
      expect(find.text('Объяснение стиха'), findsOneWidget);
      Navigator.of(tester.element(find.text('Объяснение стиха'))).pop();
      await tester.pumpAndSettle();
      await next(tester);
      expect(find.text('Конец главы').hitTestable(), findsOneWidget);
      await next(tester);
      expect(find.text(ending).hitTestable(), findsOneWidget);
      expect(find.byType(BookmarkButton), findsNothing);
      await tester.tap(find.text('Прочитать главу полностью'));
      await tester.pumpAndSettle();
      expect(find.text('Jn 10:1').hitTestable(), findsOneWidget);
      await next(tester);
      expect(find.text('Jn 10:2').hitTestable(), findsOneWidget);
      Navigator.of(tester.element(find.byType(BibleReaderScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.text(ending).hitTestable(), findsOneWidget);
    },
  );

  testWidgets('для отрывка через две главы предлагает обе главы', (
    tester,
  ) async {
    await open(tester, crossesChapter: true);
    await next(tester);
    await next(tester);
    expect(find.text('Конец отрывка').hitTestable(), findsOneWidget);
    await next(tester);
    expect(find.text('Прочитать главу 10'), findsOneWidget);
    expect(find.text('Прочитать главу 11'), findsOneWidget);
    await tester.tap(find.text('Прочитать главу 11'));
    await tester.pumpAndSettle();
    expect(find.text('Jn 11:1').hitTestable(), findsOneWidget);
  });

  for (final recordRead in [true, false]) {
    testWidgets('прогресс дневного чтения: recordRead=$recordRead', (
      tester,
    ) async {
      await open(tester, crossesChapter: false, recordRead: recordRead);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReadingScreen)),
      );
      final progress = await container.read(dayProgressProvider.future);
      expect(
        progress.isReadOn(DateTime(2026, 9, 26), CardType.reading),
        recordRead,
      );
      await tester.drag(find.byType(PageView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.text('Дневной стих').hitTestable(), findsOneWidget);
    });
  }
}
