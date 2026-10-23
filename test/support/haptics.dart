import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Записывает вибрации, которые виджет просит у платформы, например
/// `HapticFeedbackType.lightImpact`.
List<String?> recordHaptics(WidgetTester tester) {
  final haptics = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String?);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return haptics;
}
