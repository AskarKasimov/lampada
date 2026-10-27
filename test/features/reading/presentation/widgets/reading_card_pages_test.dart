import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bible/domain/entities/bible_chapter.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/presentation/widgets/reading_card_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';

void main() {
  for (final scenario in [
    (book: 'Jn', chapter: 10, lastVerse: 1, expected: 'Jn 10:2'),
    (book: 'Jn', chapter: 10, lastVerse: 2, expected: 'Jn 11:1'),
    (book: 'Jn', chapter: 21, lastVerse: 2, expected: 'Act 1:1'),
  ]) {
    testWidgets('продолжение отрывка открывает ${scenario.expected}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            analyticsProvider.overrideWithValue(FakeAnalytics()),
            bibleChapterProvider.overrideWith(
              (ref, key) async => BibleChapter(
                book: key.$1,
                number: key.$2,
                verses: [
                  BibleVerse(number: 1, text: '${key.$1} ${key.$2}:1'),
                  BibleVerse(number: 2, text: '${key.$1} ${key.$2}:2'),
                ],
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) {
                final links = ReadingCardPages(
                  reference: '${scenario.book}.${scenario.chapter}:1',
                  reading: DailyReading(
                    label: 'Дневное чтение',
                    verses: [
                      Verse(
                        chapter: scenario.chapter,
                        number: scenario.lastVerse,
                        text: 'Последний стих отрывка',
                      ),
                    ],
                  ),
                ).chapterLinks(context, continueAfterDailyReading: true);
                return Scaffold(
                  body: TextButton(
                    onPressed: links.single.onPressed,
                    child: Text(links.single.label),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(find.text(scenario.expected).hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.byType(TextButton), findsOneWidget);
    });
  }
}
