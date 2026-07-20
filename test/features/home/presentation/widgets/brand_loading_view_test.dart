import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/home/presentation/widgets/brand_loading_view.dart';
import 'package:lampada/features/home/presentation/widgets/brand_mark.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

  testWidgets('до порога — только брендинг, без спиннера', (tester) async {
    await tester.pumpWidget(
      wrap(const BrandLoadingView(spinnerDelay: Duration(seconds: 3))),
    );
    await tester.pump();

    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Чуть-чуть не дотянули — всё ещё без индикатора.
    await tester.pump(const Duration(milliseconds: 2900));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('после порога появляется спиннер, брендинг остаётся',
      (tester) async {
    await tester.pumpWidget(
      wrap(const BrandLoadingView(spinnerDelay: Duration(seconds: 3))),
    );
    await tester.pump(const Duration(milliseconds: 3100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(BrandMark), findsOneWidget);
  });

  testWidgets('снятие с экрана до порога не роняет тест на висящем таймере',
      (tester) async {
    await tester.pumpWidget(
      wrap(const BrandLoadingView(spinnerDelay: Duration(seconds: 3))),
    );
    await tester.pump();

    // Таймер должен отмениться в dispose — иначе фреймворк ругнётся на
    // pending timer при разборе дерева.
    await tester.pumpWidget(wrap(const SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 4));

    expect(find.byType(BrandLoadingView), findsNothing);
  });
}
