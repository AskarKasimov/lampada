import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/reader_progress_rail.dart';

import '../../../../support/haptics.dart';

void main() {
  Future<List<int>> pumpRail(
    WidgetTester tester, {
    required bool lampDot,
  }) async {
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ReaderProgressRail(
              count: 3,
              currentIndex: 0,
              accent: Colors.orange,
              lampDot: lampDot,
              onSelect: selected.add,
            ),
          ),
        ),
      ),
    );
    return selected;
  }

  testWidgets('без ожидающей лампады точек столько же, сколько страниц', (
    tester,
  ) async {
    await pumpRail(tester, lampDot: false);

    expect(tester.widget<ProgressDots>(find.byType(ProgressDots)).count, 3);
  });

  testWidgets('ожидающая лампада добавляет точку итога в конце', (
    tester,
  ) async {
    await pumpRail(tester, lampDot: true);

    expect(tester.widget<ProgressDots>(find.byType(ProgressDots)).count, 4);
  });

  testWidgets('до точки итога пальцем не долистать, как в «Мудрости»', (
    tester,
  ) async {
    recordHaptics(tester);
    final selected = await pumpRail(tester, lampDot: true);

    final rail = tester.getRect(find.byType(ProgressDots));
    await tester.tapAt(Offset(rail.center.dx, rail.bottom - 1));
    await tester.pump();

    expect(selected, isNotEmpty);
    expect(selected.last, 2);
  });
}
