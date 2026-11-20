import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/repositories/streak_hint_repository.dart';

class PrefsStreakHintRepository implements StreakHintRepository {
  PrefsStreakHintRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _freezeKey = 'streak_freeze_explained';

  @override
  Future<Result<bool>> freezeExplained() async {
    try {
      return Success(_prefs.getBool(_freezeKey) ?? false);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать подсказку серии',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markFreezeExplained() async {
    try {
      await requirePreferenceWrite(_prefs.setBool(_freezeKey, true));
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить подсказку серии',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
