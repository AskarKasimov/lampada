import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/tracking_consent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lampada/tracking_consent');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('возвращает ответ пользователя из нативного запроса', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'request');
      return 'authorized';
    });

    expect(await const TrackingConsent().request(), TrackingStatus.authorized);
  });

  test('без нативной части (Android, тесты) не падает', () async {
    expect(await const TrackingConsent().request(), TrackingStatus.unsupported);
  });

  test('незнакомый ответ считается неподдержанным', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'something');

    expect(await const TrackingConsent().request(), TrackingStatus.unsupported);
  });
}
