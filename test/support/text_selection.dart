import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Проверяем пользовательский жест и результат копирования, а не наличие
/// обёртки: её одного недостаточно для рабочего меню выделения.
Future<void> expectTextCanBeCopied(
  WidgetTester tester,
  Finder text, {
  required String contains,
  String? excludes,
}) async {
  String? copied;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          copied = (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
        case 'Clipboard.getData':
          return {'text': copied};
        case 'Clipboard.hasStrings':
          return {'value': copied != null};
      }
      return null;
    },
  );
  try {
    await tester.pumpAndSettle();
    await tester.longPress(text);
    await tester.pumpAndSettle();
    expect(find.text('Копировать').hitTestable(), findsOneWidget);
    final selectAll = find.text('Выбрать всё').hitTestable();
    if (selectAll.evaluate().isNotEmpty) {
      await tester.tap(selectAll);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Копировать').hitTestable());
    await tester.pumpAndSettle();
    expect(copied, stringContainsInOrder([contains]));
    if (excludes != null) {
      expect(copied, isNot(stringContainsInOrder([excludes])));
    }
    expect(tester.takeException(), isNull);
  } finally {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  }
}
