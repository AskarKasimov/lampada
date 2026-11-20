import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/profile/data/repositories/prefs_review_prompt_repository.dart';
import 'package:lampada/features/profile/domain/repositories/review_prompt_repository.dart';
import 'package:lampada/features/profile/domain/usecases/claim_review_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late ClaimReviewRequest claim;

  setUp(() async {
    now = DateTime(2026, 11, 10, 9);
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsReviewPromptRepository(
      await SharedPreferences.getInstance(),
    );
    claim = ClaimReviewRequest(repository, clock: () => now);
  });

  group('после закрытия раздела', () {
    test('в первый день просим один раз', () async {
      await claim.recordAppOpen();
      expect(await claim.afterReading(), ReviewMoment.firstReading);
      expect(await claim.afterReading(), isNull);
      now = now.add(const Duration(hours: 10));
      expect(await claim.afterReading(), isNull);
    });

    test('в любой следующий день просим ещё раз, тоже один раз', () async {
      await claim.recordAppOpen();
      await claim.afterReading();
      now = DateTime(2026, 11, 13, 8);

      expect(await claim.afterReading(), ReviewMoment.nextDayReturn);
      expect(await claim.afterReading(), isNull);
      now = DateTime(2026, 11, 20, 8);
      expect(await claim.afterReading(), isNull);
    });

    test('два запроса в один день не показываем', () async {
      // В первый день юзер ничего не закрывал.
      await claim.recordAppOpen();
      now = DateTime(2026, 11, 11, 8);

      expect(await claim.afterReading(), ReviewMoment.firstReading);
      expect(await claim.afterReading(), isNull);
      now = DateTime(2026, 11, 12, 8);
      expect(await claim.afterReading(), isNull);
    });

    test('без записанного дня первого входа он начинается сегодня', () async {
      expect(await claim.afterReading(), ReviewMoment.firstReading);
      now = DateTime(2026, 11, 11, 8);
      expect(await claim.afterReading(), ReviewMoment.nextDayReturn);
    });
  });

  group('при входе в приложение', () {
    test('в день первого входа не просим, а только запоминаем день', () async {
      expect(await claim.afterAppOpen(), isFalse);
      now = now.add(const Duration(hours: 10));
      expect(await claim.afterAppOpen(), isFalse);

      expect(await claim.afterReading(), ReviewMoment.firstReading);
    });

    test('в любой следующий день просим один раз', () async {
      await claim.afterAppOpen();
      now = DateTime(2026, 11, 12, 8);

      expect(await claim.afterAppOpen(), isTrue);
      expect(await claim.afterAppOpen(), isFalse);
      now = DateTime(2026, 11, 20, 8);
      expect(await claim.afterAppOpen(), isFalse);
    });

    test('без записанного дня первого входа не просим', () async {
      // Первый вход сохранился бы, но день не записался: сегодня и есть
      // первый день.
      expect(await claim.afterAppOpen(), isFalse);
    });

    test('recordAppOpen только запоминает день', () async {
      await claim.recordAppOpen();
      now = DateTime(2026, 11, 11, 8);
      await claim.recordAppOpen();

      expect(await claim.afterAppOpen(), isTrue);
    });
  });

  group('не больше одного запроса в день', () {
    test('после запроса при входе закрытие раздела ждёт другого дня', () async {
      await claim.afterAppOpen();
      await claim.afterReading();
      now = DateTime(2026, 11, 11, 8);

      expect(await claim.afterAppOpen(), isTrue);
      expect(await claim.afterReading(), isNull);
      now = DateTime(2026, 11, 12, 8);
      expect(await claim.afterReading(), ReviewMoment.nextDayReturn);
    });

    test('после запроса за разделом вход ждёт другого дня', () async {
      await claim.afterAppOpen();
      await claim.afterReading();
      now = DateTime(2026, 11, 11, 8);
      expect(await claim.afterReading(), ReviewMoment.nextDayReturn);

      expect(await claim.afterAppOpen(), isFalse);
      now = DateTime(2026, 11, 12, 8);
      expect(await claim.afterAppOpen(), isTrue);
    });
  });
}
