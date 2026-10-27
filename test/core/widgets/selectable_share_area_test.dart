import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_event.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/widgets/selectable_share_area.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import '../../support/fake_analytics.dart';
import '../../support/text_selection.dart';

class _RecordingSharePlatform extends SharePlatform {
  ShareParams? params;

  @override
  Future<ShareResult> share(ShareParams params) async {
    this.params = params;
    return ShareResult.unavailable;
  }
}

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('одно долгое нажатие открывает копирование на $platform', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(platform: platform),
            home: const Scaffold(
              body: SelectableShareArea(
                child: Center(child: Text('Проверяем выделение')),
              ),
            ),
          ),
        ),
      );
      await expectTextCanBeCopied(
        tester,
        find.text('Проверяем выделение'),
        contains: 'Проверяем выделение',
      );
    });
  }
  testWidgets('не блокирует листание до выделения и после копирования', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PageView(
              children: const [
                SelectableShareArea(child: Center(child: Text('Первая'))),
                SelectableShareArea(child: Center(child: Text('Вторая'))),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Вторая'), findsOneWidget);
    await expectTextCanBeCopied(
      tester,
      find.text('Вторая'),
      contains: 'Вторая',
    );
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Первая'), findsOneWidget);
  });

  testWidgets('показывает «Поделиться» в меню выделения', (tester) async {
    final originalPlatform = SharePlatform.instance;
    final platform = _RecordingSharePlatform();
    SharePlatform.instance = platform;
    addTearDown(() => SharePlatform.instance = originalPlatform);

    final analytics = FakeAnalytics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
        child: const MaterialApp(
          home: Scaffold(
            body: SelectableShareArea(
              content: SharedContent.bibleVerse,
              child: Center(child: Text('Текст материала')),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Текст материала'));
    await tester.pumpAndSettle();

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.text('Копировать'), findsOneWidget);
    expect(find.text('Выбрать всё'), findsOneWidget);
    expect(find.text('Поделиться'), findsOneWidget);

    await tester.tap(find.text('Поделиться'));
    await tester.pump();

    expect(
      platform.params?.text,
      'Текст материала\n\n'
      'Приложение Лампада:\n'
      'App Store: https://clck.su/gXEhl\n'
      'RuStore: https://clck.su/hdeZJ',
    );
    expect(platform.params?.sharePositionOrigin, isNotNull);
    expect(analytics.single('content_shared'), {
      'content': 'bible_verse',
      'method': 'selection',
      'result': 'unavailable',
    });
  });
}
