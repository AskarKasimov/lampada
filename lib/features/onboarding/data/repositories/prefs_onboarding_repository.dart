import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../domain/repositories/onboarding_repository.dart';

class PrefsOnboardingRepository implements OnboardingRepository {
  PrefsOnboardingRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'onboarding_shown';

  @override
  Future<Result<bool>> wasShown() async {
    try {
      return Success(_prefs.getBool(_key) ?? false);
    } on Exception catch (e) {
      // Не смогли прочитать — считаем, что показывали: лишний раз встречать
      // приветствием того, кто им уже пользуется, хуже, чем не показать его
      // новичку.
      return Failure(
        AppFailure(
          'Не удалось прочитать состояние онбординга',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markShown() async {
    try {
      await _prefs.setBool(_key, true);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить состояние онбординга',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
