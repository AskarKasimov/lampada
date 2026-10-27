import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/rail_scrubber.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/reader_progress_rail.dart';

import '../../../../support/haptics.dart';

void main() {
  const count = 5;

  Future<List<int>> pumpScrubber(WidgetTester tester, {int current = 0}) async {
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            // Колонка шириной в зону касания, как слева в читалке.
            child: SizedBox(
              width: 32,
              child: Center(
                child: RailScrubber(
                  count: count,
                  currentIndex: current,
                  onSelect: selected.add,
                  child: ProgressDots(
                    count: count,
                    currentIndex: current,
                    axis: Axis.vertical,
                    accentColors: List.filled(count, Colors.brown),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return selected;
  }

  testWidgets('ведёт пальцем вниз: страницы по очереди, щелчок на каждой', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    final selected = await pumpScrubber(tester);

    final rail = tester.getRect(find.byType(RailScrubber));
    final gesture = await tester.startGesture(
      rail.topCenter + const Offset(0, 1),
    );
    for (var y = 1.0; y < rail.height; y += 2) {
      await gesture.moveTo(rail.topCenter + Offset(0, y));
    }
    await gesture.up();

    // С текущей страницы не прыгаем, дальше каждая страница один раз.
    expect(selected, [1, 2, 3, 4]);
    expect(haptics, List.filled(4, 'HapticFeedbackType.selectionClick'));
  });

  testWidgets('тап по столбику открывает страницу под пальцем', (tester) async {
    final haptics = recordHaptics(tester);
    final selected = await pumpScrubber(tester);

    final rail = tester.getRect(find.byType(RailScrubber));
    await tester.tapAt(rail.bottomCenter - const Offset(0, 1));

    expect(selected, [count - 1]);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('за точки можно взяться и сбоку от них', (tester) async {
    final selected = await pumpScrubber(tester, current: 2);

    final rail = tester.getRect(find.byType(RailScrubber));
    // Сами точки 8 pt шириной; пальцу нужна полоса шире.
    expect(rail.width, greaterThanOrEqualTo(32));
    await tester.tapAt(rail.bottomLeft + const Offset(2, -1));

    expect(selected, [count - 1]);
  });

  testWidgets('столбик читалки листается пальцем, когда ему дали onSelect', (
    tester,
  ) async {
    final selected = <int>[];
    Widget rail({ValueChanged<int>? onSelect}) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 32,
            height: 400,
            child: Center(
              child: ReaderProgressRail(
                count: 10,
                currentIndex: 0,
                accent: Colors.brown,
                onSelect: onSelect,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(rail());
    expect(find.byType(RailScrubber), findsNothing);

    await tester.pumpWidget(rail(onSelect: selected.add));
    final rect = tester.getRect(find.byType(RailScrubber));
    await tester.tapAt(rect.bottomCenter - const Offset(0, 1));
    expect(selected, [9]);
  });
}
