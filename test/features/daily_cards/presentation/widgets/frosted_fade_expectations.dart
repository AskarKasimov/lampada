import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/frosted_fade.dart';

/// Край матового стекла внутри [glass] растворяется плавно: в зоне
/// растворения одно размытие той же силы, что у самого стекла, под
/// градиентной маской, а не полосы с разной силой размытия («ступеньки»).
void expectSmoothFade(WidgetTester tester, Finder glass) {
  final fade = find.descendant(of: glass, matching: find.byType(FrostedFade));
  expect(fade, findsOneWidget);
  final fadeFilters = find.descendant(
    of: fade,
    matching: find.byType(BackdropFilter),
  );
  expect(fadeFilters, findsOneWidget);
  final mask = find.descendant(of: fade, matching: find.byType(ShaderMask));
  expect(mask, findsOneWidget);
  expect(tester.widget<ShaderMask>(mask).blendMode, BlendMode.dstIn);

  final filters = tester
      .widgetList<BackdropFilter>(
        find.descendant(of: glass, matching: find.byType(BackdropFilter)),
      )
      .map((filter) => filter.filter.toString())
      .toSet();
  expect(filters, hasLength(1), reason: 'размытие одной силы по всему стеклу');
}
