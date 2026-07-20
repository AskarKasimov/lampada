import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/home/presentation/widgets/stale_cache_notice.dart';

void main() {
  testWidgets('показывает дату кэша по-русски и зовёт onRefresh', (tester) async {
    var refreshed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StaleCacheNotice(
            staleDate: DateTime(2026, 7, 19),
            onRefresh: () => refreshed++,
          ),
        ),
      ),
    );

    expect(find.text('Офлайн · карточки за 19 июля'), findsOneWidget);

    await tester.tap(find.text('Обновить'));
    await tester.pump();

    expect(refreshed, 1);
  });
}
