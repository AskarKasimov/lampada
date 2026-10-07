import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/streak_card.dart';

final _today = DateTime(2026, 10, 7);

DayProgress _visited(List<int> daysAgo) => DayProgress(
  readTypes: const {},
  visitedDays: {
    for (final ago in daysAgo)
      dateKey(DateTime(_today.year, _today.month, _today.day - ago)),
  },
);

Widget _app(DayProgress progress) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: StreakCard(progress: progress, today: _today),
  ),
);

Finder _lamp(String state) =>
    find.image(AssetImage('assets/illustrations/lampada_$state.png'));

void main() {
  testWidgets('серия показывает горящую лампаду и число дней', (tester) async {
    await tester.pumpWidget(_app(_visited([0, 1, 2])));

    expect(find.text('3'), findsOneWidget);
    expect(find.text('дня подряд'), findsOneWidget);
    expect(_lamp('on'), findsOneWidget);
    // Неделя уже есть в полоске наверху, второго ряда дней нет.
    expect(find.text('пн'), findsNothing);
  });

  testWidgets('без серии лампада погашена и зовёт начать', (tester) async {
    await tester.pumpWidget(_app(_visited([])));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('дней подряд'), findsOneWidget);
    expect(_lamp('off'), findsOneWidget);
    expect(_lamp('on'), findsNothing);
    expect(
      find.text('Начните с «Мудрости дня», и лампада загорится.'),
      findsOneWidget,
    );
  });

  final messages = {
    'серия идёт, сегодня не читали': (
      [1, 2, 3],
      'Загляните в «Мудрость дня», чтобы лампада не погасла.',
    ),
    'первый день': (
      [0],
      'Хорошее начало. Загляните завтра, чтобы лампада не погасла.',
    ),
    'несколько дней': (
      [0, 1, 2],
      'Вы на верном пути. Загляните завтра, чтобы лампада горела дальше.',
    ),
    // Отдельной фразы для недели нет: число дней и так видно.
    'неделя и больше': (
      [0, 1, 2, 3, 4, 5, 6],
      'Вы на верном пути. Загляните завтра, чтобы лампада горела дальше.',
    ),
  };
  for (final MapEntry(key: name, value: (days, text)) in messages.entries) {
    testWidgets('подсказка серии: $name', (tester) async {
      await tester.pumpWidget(_app(_visited(days)));
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('в карточке серии нет кнопки «Поделиться»', (tester) async {
    await tester.pumpWidget(_app(_visited([0])));

    expect(find.byIcon(CupertinoIcons.share), findsNothing);
    expect(find.byTooltip('Поделиться'), findsNothing);
  });

  test('подпись к числу дней согласована по падежу', () {
    expect(streakDaysLabel(1), 'день подряд');
    expect(streakDaysLabel(2), 'дня подряд');
    expect(streakDaysLabel(5), 'дней подряд');
    expect(streakDaysLabel(11), 'дней подряд');
    expect(streakDaysLabel(14), 'дней подряд');
    expect(streakDaysLabel(21), 'день подряд');
    expect(streakDaysLabel(22), 'дня подряд');
  });
}
