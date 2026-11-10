import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/profile/data/repositories/prefs_review_prompt_repository.dart';
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

  group('после первого чтения', () {
    test('оценку просим один раз', () async {
      expect(await claim.afterReading(), isTrue);
      expect(await claim.afterReading(), isFalse);
    });
  });

  group('при входе в приложение', () {
    test('в день первого входа оценку не просим', () async {
      expect(await claim.onAppOpen(), isFalse);
      now = now.add(const Duration(hours: 10));
      expect(await claim.onAppOpen(), isFalse);
    });

    test('на следующий день просим один раз', () async {
      await claim.onAppOpen();
      now = DateTime(2026, 11, 11, 8);

      expect(await claim.onAppOpen(), isTrue);
      expect(await claim.onAppOpen(), isFalse);
      now = DateTime(2026, 11, 12, 8);
      expect(await claim.onAppOpen(), isFalse);
    });

    test('вернувшийся позже следующего дня тоже получает запрос', () async {
      await claim.onAppOpen();
      now = DateTime(2026, 11, 20, 8);

      expect(await claim.onAppOpen(), isTrue);
    });

    test('запрос после чтения не отменяет запрос на следующий день', () async {
      await claim.onAppOpen();
      expect(await claim.afterReading(), isTrue);
      now = DateTime(2026, 11, 11, 8);

      expect(await claim.onAppOpen(), isTrue);
    });
  });
}
