import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/today_offline_view.dart';

void main() {
  testWidgets('называет выбранную дату без кэша', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TodayOfflineView(
            date: DateTime(2026, 8, 9),
            kind: FailureKind.network,
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('Карточки за 9 августа не загружены'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}
