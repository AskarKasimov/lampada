import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/preference_write.dart';

void main() {
  test('завершает запись, подтверждённую платформой', () async {
    await expectLater(requirePreferenceWrite(Future.value(true)), completes);
  });

  test('отклоняет запись, не подтверждённую платформой', () async {
    await expectLater(
      requirePreferenceWrite(Future.value(false)),
      throwsA(isA<Exception>()),
    );
  });
}
