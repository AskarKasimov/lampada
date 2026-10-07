import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/shell/presentation/providers/shell_providers.dart';
import 'package:lampada/features/shell/presentation/widgets/floating_nav_bar.dart';

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
}
