import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/shell/presentation/providers/shell_providers.dart';
import 'package:lampada/features/shell/presentation/widgets/floating_nav_bar.dart';

import '../../../../support/haptics.dart';

/// Расстояние от нижнего края капсулы до низа экрана.
Future<double> _bottomGap(
  WidgetTester tester, {
  required TargetPlatform platform,
  required double bottomInset,
}) async {
  const screen = Size(402, 874);
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light.copyWith(platform: platform),
      home: MediaQuery(
        data: MediaQueryData(
          size: screen,
          padding: EdgeInsets.only(bottom: bottomInset),
          viewPadding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavBar(current: ShellTab.today, onSelect: (_) {}),
          ),
        ),
      ),
    ),
  );

  final rect = tester.getRect(find.byType(ClipRRect).first);
  return screen.height - rect.bottom;
}

void main() {
  testWidgets('на iOS капсула опускается в зону home indicator', (
    tester,
  ) async {
    final gap = await _bottomGap(
      tester,
      platform: TargetPlatform.iOS,
      bottomInset: 34,
    );

    expect(gap, lessThan(34));
    expect(gap, greaterThanOrEqualTo(14));
  });

  testWidgets('на Android капсула не заходит на системную навигацию', (
    tester,
  ) async {
    final gap = await _bottomGap(
      tester,
      platform: TargetPlatform.android,
      bottomInset: 48,
    );

    expect(gap, greaterThanOrEqualTo(48));
  });

  testWidgets('без нижнего inset капсула держит отступ от края', (
    tester,
  ) async {
    final gap = await _bottomGap(
      tester,
      platform: TargetPlatform.iOS,
      bottomInset: 0,
    );

    expect(gap, greaterThanOrEqualTo(10));
  });

  Future<List<ShellTab>> pumpBar(WidgetTester tester) async {
    final selected = <ShellTab>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavBar(
              current: ShellTab.today,
              onSelect: selected.add,
            ),
          ),
        ),
      ),
    );
    return selected;
  }

  double scaleOf(WidgetTester tester, String label) => tester
      .widget<AnimatedScale>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedScale),
        ),
      )
      .scale;

  testWidgets('нажатая вкладка сжимается и отпружинивает, как в iOS', (
    tester,
  ) async {
    await pumpBar(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Библия')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(scaleOf(tester, 'Библия'), lessThan(1));
    // Соседние вкладки не реагируют.
    expect(scaleOf(tester, 'Профиль'), 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester, 'Библия'), 1);
    // Материальной «волны» от тапа нет: она не похожа на iOS.
    expect(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('тап по вкладке переключает её с лёгким щелчком', (tester) async {
    final haptics = recordHaptics(tester);
    final selected = await pumpBar(tester);

    await tester.tap(find.text('Библия'));
    await tester.pumpAndSettle();

    expect(selected, [ShellTab.bible]);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });
}
