import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/widgets/selectable_share_area.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class _RecordingSharePlatform extends SharePlatform {
  ShareParams? params;

  @override
  Future<ShareResult> share(ShareParams params) async {
    this.params = params;
    return ShareResult.unavailable;
  }
}

void main() {
  testWidgets('не блокирует горизонтальное листание до долгого нажатия', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageView(
            children: const [
              SelectableShareArea(child: Center(child: Text('Первая'))),
              SelectableShareArea(child: Center(child: Text('Вторая'))),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Вторая'), findsOneWidget);
  });

  testWidgets('показывает «Поделиться» в меню выделения', (tester) async {
    final originalPlatform = SharePlatform.instance;
    final platform = _RecordingSharePlatform();
    SharePlatform.instance = platform;
    addTearDown(() => SharePlatform.instance = originalPlatform);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SelectableShareArea(
            child: Center(child: Text('Текст материала')),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Текст материала'));
    await tester.pump();
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
      'материала\n\n'
      'App Store: '
      'https://apps.apple.com/ru/app/%D0%BB%D0%B0%D0%BC%D0%BF%D0%B0%D0%B4%D0%B0-%D1%82%D0%BE%D0%BB%D0%BA%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D0%B5%D0%B2%D0%B0%D0%BD%D0%B3%D0%B5%D0%BB%D0%B8%D1%8F/id6799424044\n'
      'RuStore: https://www.rustore.ru/catalog/app/ru.lampada.lampada',
    );
    expect(platform.params?.sharePositionOrigin, isNotNull);
  });
}
