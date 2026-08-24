import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/profile/presentation/services/profile_actions_service.dart';

void main() {
  test('на Android отзыв запрашивается через RuStore', () async {
    final calls = <String>[];
    final actions = PlatformProfileActionsService(
      isAndroid: true,
      requestAppStoreReview: () async => calls.add('app-store'),
      requestRustoreReview: () async => calls.add('rustore'),
    );

    expect(await actions.requestReview(), isTrue);

    expect(calls, ['rustore']);
  });

  test('на Android недоступный RuStore возвращает неуспех', () async {
    final actions = PlatformProfileActionsService(
      isAndroid: true,
      requestRustoreReview: () async => throw StateError('RuStore not found'),
    );

    expect(await actions.requestReview(), isFalse);
  });

  test('на iOS недоступный StoreKit возвращает неуспех', () async {
    final actions = PlatformProfileActionsService(
      isAndroid: false,
      requestAppStoreReview: () async => throw StateError('StoreKit error'),
    );

    expect(await actions.requestReview(), isFalse);
  });
}
