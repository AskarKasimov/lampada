import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/lamp_level.dart';
import 'package:lampada/core/widgets/lampada_mark.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

  testWidgets('рендерится без стрика — для loading и offline', (tester) async {
    await tester.pumpWidget(wrap(const LampadaMark()));
    await tester.pump();

    expect(find.byType(LampadaMark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('негорящая лампада не падает и остаётся на экране',
      (tester) async {
    await tester.pumpWidget(wrap(const LampadaMark(level: LampLevel.unlit)));
    await tester.pump();

    expect(find.byType(LampadaMark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('с heroTag оборачивается в Hero, без него — нет',
      (tester) async {
    await tester.pumpWidget(wrap(const LampadaMark(heroTag: 'lampada')));
    await tester.pump();
    expect(find.byType(Hero), findsOneWidget);

    await tester.pumpWidget(wrap(const LampadaMark()));
    await tester.pump();
    expect(find.byType(Hero), findsNothing);
  });
}
