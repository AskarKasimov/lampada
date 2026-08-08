import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_swipe_nudge.dart';

void main() {
  testWidgets('начинается после показа экрана и плавно возвращается', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CardSwipeNudge(child: SizedBox.expand())),
    );

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 20));
    expect(_horizontalOffset(tester), 0);

    await tester.pump(const Duration(milliseconds: 180));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_horizontalOffset(tester), lessThan(-20));

    await tester.pump(const Duration(milliseconds: 800));
    expect(_horizontalOffset(tester), 0);
  });
}

double _horizontalOffset(WidgetTester tester) =>
    tester.widget<Transform>(find.byType(Transform)).transform.storage[12];
