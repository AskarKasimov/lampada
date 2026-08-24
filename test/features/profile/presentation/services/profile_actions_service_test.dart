import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/profile/presentation/services/profile_actions_service.dart';

void main() {
  test('текст шаринга содержит ссылки на оба магазина', () {
    expect(
      shareText,
      contains(
        'https://apps.apple.com/ru/app/%D0%BB%D0%B0%D0%BC%D0%BF%D0%B0%D0%B4%D0%B0-%D1%82%D0%BE%D0%BB%D0%BA%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D0%B5%D0%B2%D0%B0%D0%BD%D0%B3%D0%B5%D0%BB%D0%B8%D1%8F/id6799424044',
      ),
    );
    expect(
      shareText,
      contains('https://www.rustore.ru/catalog/app/ru.lampada.lampada'),
    );
  });

  test('на Android подпись отзыва называет RuStore', () {
    final actions = PlatformProfileActionsService(isAndroid: true);

    expect(actions.reviewLabel, 'Оставить отзыв в RuStore');
  });

  test('на iOS подпись отзыва называет App Store', () {
    final actions = PlatformProfileActionsService(isAndroid: false);

    expect(actions.reviewLabel, 'Оставить отзыв в App Store');
  });

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
