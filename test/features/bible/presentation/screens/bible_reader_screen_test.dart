import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bible/domain/entities/bible_book.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/screens/bible_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/rail_scrubber.dart';
import 'package:lampada/features/reading/presentation/widgets/verse_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';
import '../../../../support/haptics.dart';

void main() {
  late SharedPreferences prefs;
  late FakeAnalytics analytics;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    analytics = FakeAnalytics();
  });

  Future<void> open(WidgetTester tester, {required int verse}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWithValue(analytics),
          bibleChapterProvider.overrideWith(
            (ref, key) async => const BibleChapter(
              book: 'Gen',
              number: 1,
              verses: [
                BibleVerse(number: 1, text: 'В начале'),
                BibleVerse(
                  number: 2,
                  text: 'Земля же была безвидна',
                  interpretation: 'Объяснение второго стиха',
                  interpretationRange: 'Быт.1:2',
                ),
              ],
              interpretationAuthor: 'Толковая Библия А.П. Лопухина',
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: BibleReaderScreen(
            book: bibleBooks.first,
            chapter: 1,
            initialVerse: verse,
            showClose: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('стих без толкования не обещает его кнопкой', (tester) async {
    await open(tester, verse: 1);

    expect(find.text('В начале').hitTestable(), findsOneWidget);
    expect(find.byType(VerseInterpretationButton), findsNothing);
  });

  testWidgets('толкование открывается со стиха главы, как в чтении дня', (
    tester,
  ) async {
    await open(tester, verse: 2);

    await tester.tap(find.byType(VerseInterpretationButton));
    await tester.pumpAndSettle();

    expect(find.text('Объяснение второго стиха'), findsOneWidget);
    expect(find.text('на Быт.1:2'), findsOneWidget);
    expect(find.text('— Толковая Библия А.П. Лопухина'), findsOneWidget);
    expect(analytics.names, contains('interpretation_opened'));
  });

  testWidgets('под стихом сокращение книги, глава и стих', (tester) async {
    await open(tester, verse: 1);

    expect(find.text('Быт. 1:1').hitTestable(), findsOneWidget);
    expect(find.text('1:1'), findsNothing);
  });

  testWidgets('по столбику точек стихи листаются пальцем со щелчком', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    await open(tester, verse: 1);

    final rail = tester.getRect(find.byType(RailScrubber));
    await tester.tapAt(rail.bottomCenter - const Offset(0, 1));
    await tester.pumpAndSettle();

    expect(find.text('Земля же была безвидна').hitTestable(), findsOneWidget);
    expect(find.text('Быт. 1:2').hitTestable(), findsOneWidget);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });
}
