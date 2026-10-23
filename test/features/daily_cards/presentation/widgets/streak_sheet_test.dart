import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/streak_sheet.dart';

/// Четверг: неделя шторки идёт с понедельника 19 по воскресенье 25 октября.
final _today = DateTime(2026, 10, 22, 6, 16);

const _progress = DayProgress(
  readTypes: {},
  visitedDays: {
    '2026-03-01',
    '2026-03-02',
    '2026-03-03',
    '2026-10-19',
    '2026-10-22',
    '2025-12-31',
  },
);

Widget _app({
  DayProgress progress = _progress,
  int read = 14,
  ThemeData? theme,
}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Scaffold(
    body: StreakSheet(
      progress: progress,
      today: _today,
      bibleChaptersRead: read,
      bibleChaptersTotal: 1361,
    ),
  ),
);

void main() {
  test('доля Библии: первые главы не выглядят как ноль', () {
    expect(bibleReadPercentLabel(0, 1361), '0%');
    expect(bibleReadPercentLabel(3, 1361), '<1%');
    expect(bibleReadPercentLabel(14, 1361), '1%');
    expect(bibleReadPercentLabel(1361, 1361), '100%');
    expect(bibleReadPercentLabel(2000, 1361), '100%');
    expect(bibleReadPercentLabel(5, 0), '0%');
  });

  testWidgets('шторка показывает серию, лучшую серию и Библию', (tester) async {
    await tester.pumpWidget(_app());

    expect(
      find.text('Лампадка помогает сделать чтение ежедневной привычкой'),
      findsOneWidget,
    );
    // Заголовок и крупные числа набраны Lora, подписи системным шрифтом.
    String? family(String text) =>
        tester.widget<Text>(find.text(text)).style?.fontFamily;
    expect(
      family('Лампадка помогает сделать чтение ежедневной привычкой'),
      'Lora',
    );
    expect(family('1%'), 'Lora');
    expect(family('Дней подряд'), isNull);
    expect(find.text('Дней подряд'), findsOneWidget);
    expect(find.text('Лучшая: 3'), findsOneWidget);
    expect(find.text('Библия'), findsOneWidget);
    expect(find.text('1%'), findsOneWidget);
    expect(find.text('Прочитано глав: 14'), findsOneWidget);
    expect(find.text('В этом году лампада горела 5 дней'), findsOneWidget);
  });

  testWidgets('без активности в году итог зовёт мягко', (tester) async {
    await tester.pumpWidget(
      _app(
        progress: const DayProgress(readTypes: {}, visitedDays: {}),
        read: 0,
      ),
    );

    expect(find.text('Лучшая: 0'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('В этом году лампада ещё не загоралась'), findsOneWidget);
  });

  testWidgets('неделя с понедельника, сегодня в акцентном круге', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    for (final day in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']) {
      expect(find.text(day), findsOneWidget);
    }
    for (var day = 19; day <= 25; day++) {
      expect(find.text('$day'), findsOneWidget);
    }
    final circle = tester.widget<Container>(
      find
          .ancestor(of: find.text('22'), matching: find.byType(Container))
          .first,
    );
    expect(
      (circle.decoration! as BoxDecoration).color,
      AppColorsExtension.light.accent,
    );
    final other = tester.widget<Container>(
      find
          .ancestor(of: find.text('21'), matching: find.byType(Container))
          .first,
    );
    expect((other.decoration as BoxDecoration?)?.color, isNull);
  });

  testWidgets('дни с активностью отмечены точкой', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.byKey(const ValueKey('lit-2026-10-19')), findsOneWidget);
    expect(find.byKey(const ValueKey('lit-2026-10-22')), findsOneWidget);
    expect(find.byKey(const ValueKey('lit-2026-10-20')), findsNothing);
    expect(
      find.bySemanticsLabel('19 октября, понедельник, лампада горела'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('22 октября, четверг, сегодня, лампада горела'),
      findsOneWidget,
    );
  });

  for (final dark in [false, true]) {
    testWidgets('крупный шрифт не ломает шторку, тёмная тема: $dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        _app(theme: dark ? AppTheme.dark : AppTheme.light),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Дней подряд'), findsOneWidget);
    });
  }
}
