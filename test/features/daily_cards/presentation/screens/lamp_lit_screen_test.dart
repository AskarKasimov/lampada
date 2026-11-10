import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/presentation/screens/lamp_lit_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/streak_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const before = DayProgress(readTypes: {}, visitedDays: {});
  LampLitExit? exit;

  /// Прогресс в хранилище уже зажжён: страницу открывают после записи.
  Future<void> pumpLauncher(
    WidgetTester tester, {
    bool canContinue = true,
    bool settle = true,
  }) async {
    exit = null;
    SharedPreferences.setMockInitialValues({
      'flutter.day_progress': jsonEncode({
        'date': dateKey(DateTime.now()),
        'readTypes': <String>[],
        'visitedDays': [dateKey(DateTime.now())],
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => exit = await showLampLit(
                  context,
                  before: before,
                  title: 'Память дня прочитана',
                  canContinue: canContinue,
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Маршрут выехал, представление только началось.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  StreakCard card(WidgetTester tester) =>
      tester.widget<StreakCard>(find.byType(StreakCard));

  testWidgets('итог раздела зажигает лампаду на глазах, как «Мудрость»', (
    tester,
  ) async {
    await pumpLauncher(tester);

    expect(find.text('Слава Богу!'), findsOneWidget);
    expect(find.text('Память дня прочитана'), findsOneWidget);
    expect(card(tester).progress.isLit(DateTime.now()), isTrue);
    expect(card(tester).showWeek, isTrue);
  });

  testWidgets('до конца представления показана серия до зажжения', (
    tester,
  ) async {
    await pumpLauncher(tester, settle: false);

    expect(card(tester).progress.isLit(DateTime.now()), isFalse);
    expect(card(tester).showWeek, isFalse);
    await tester.pumpAndSettle();
  });

  testWidgets('«Продолжить чтение» возвращает к разделу', (tester) async {
    await pumpLauncher(tester);

    await tester.tap(find.text('Продолжить чтение'));
    await tester.pumpAndSettle();

    expect(exit, LampLitExit.continueReading);
    expect(find.byType(LampLitScreen), findsNothing);
  });

  testWidgets('дочитанный до конца раздел ведёт только на главную', (
    tester,
  ) async {
    await pumpLauncher(tester, canContinue: false);

    expect(find.text('Продолжить чтение'), findsNothing);
    await tester.tap(find.text('Вернуться на главную'));
    await tester.pumpAndSettle();

    expect(exit, LampLitExit.home);
  });
}
