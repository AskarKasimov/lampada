import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/card_viewer_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/day_wisdom_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:lampada/features/reading/presentation/widgets/verse_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('единая листалка ведёт от притчи к первому стиху', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const cards = [
      DayCard(
        id: 'quote',
        type: CardType.quote,
        body: 'Цитата',
        source: 'Источник',
      ),
      DayCard(
        id: 'advice',
        type: CardType.advice,
        body: 'Совет',
        source: 'Источник',
      ),
      DayCard(
        id: 'parable',
        type: CardType.parable,
        body: 'Притча',
        source: 'Источник',
      ),
      DayCard(
        id: 'reading',
        type: CardType.reading,
        body: 'Ин.10:1',
        source: 'Источник',
        reference: 'Jn.10:1',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith(
            (ref, reference) async => const DailyReading(
              label: 'Ин.10:1',
              verses: [Verse(number: 1, chapter: 10, text: 'Первый стих')],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DayWisdomScreen(
            cards: cards,
            startIndex: 2,
            date: DateTime(2026, 9, 29),
            recordProgress: false,
            recordRead: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Притча'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byType(VerseView), findsOneWidget);
    expect(find.text('Первый стих'), findsOneWidget);
  });

  testWidgets('загрузка не засчитывает Евангелие до первого стиха', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final pending = Completer<DailyReading>();
    final date = DateTime.now();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith((ref, reference) => pending.future),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DayWisdomScreen(
            cards: const [
              DayCard(
                id: 'reading',
                type: CardType.reading,
                body: 'Ин.10:1',
                source: 'Источник',
                reference: 'Jn.10:1',
              ),
            ],
            startIndex: 0,
            date: date,
            recordProgress: false,
            recordRead: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Загружаем Евангелие дня'), findsOneWidget);
    expect(find.byType(CardViewerScreen), findsNothing);
    expect(find.byType(ProgressDots), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayWisdomScreen)),
    );
    expect(
      (await container.read(
        dayProgressProvider.future,
      )).isReadOn(date, CardType.reading),
      isFalse,
    );

    pending.complete(
      const DailyReading(
        label: 'Ин.10:1',
        verses: [Verse(number: 1, chapter: 10, text: 'Загруженный стих')],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Загруженный стих'), findsOneWidget);
    expect(
      (await container.read(
        dayProgressProvider.future,
      )).isReadOn(date, CardType.reading),
      isTrue,
    );
  });

  testWidgets('ошибка Евангелия оставляет цитату и позволяет повторить', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    final date = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith((ref, reference) async {
            attempts++;
            if (attempts == 1) throw StateError('сеть недоступна');
            return const DailyReading(
              label: 'Ин.10:1',
              verses: [
                Verse(number: 1, chapter: 10, text: 'Стих после повтора'),
              ],
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DayWisdomScreen(
            cards: const [
              DayCard(
                id: 'quote',
                type: CardType.quote,
                body: 'Доступная цитата',
                source: 'Источник',
              ),
              DayCard(
                id: 'reading',
                type: CardType.reading,
                body: 'Ин.10:1',
                source: 'Источник',
                reference: 'Jn.10:1',
              ),
            ],
            startIndex: 1,
            date: date,
            recordProgress: false,
            recordRead: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayWisdomScreen)),
    );
    expect(find.text('Евангелие дня сейчас недоступно'), findsOneWidget);
    expect(
      (await container.read(
        dayProgressProvider.future,
      )).isReadOn(date, CardType.reading),
      isFalse,
    );
    await tester.drag(find.byType(PageView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Доступная цитата'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Стих после повтора'), findsOneWidget);
  });

  testWidgets('пустой отрывок не засчитывается прочитанным', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final date = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dailyReadingProvider.overrideWith(
            (ref, reference) async =>
                const DailyReading(label: 'Ин.10:1', verses: []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: DayWisdomScreen(
            cards: const [
              DayCard(
                id: 'reading',
                type: CardType.reading,
                body: 'Ин.10:1',
                source: 'Источник',
                reference: 'Jn.10:1',
              ),
            ],
            startIndex: 0,
            date: date,
            recordProgress: false,
            recordRead: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Евангелие дня сейчас недоступно'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayWisdomScreen)),
    );
    expect(
      (await container.read(
        dayProgressProvider.future,
      )).isReadOn(date, CardType.reading),
      isFalse,
    );
  });
}
