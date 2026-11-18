import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/repositories/return_prompt_repository.dart';

class PrefsReturnPromptRepository implements ReturnPromptRepository {
  PrefsReturnPromptRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _firstOpenDayKey = 'reminders_first_open_day';
  static const _promptedKey = 'reminders_return_prompted';

  @override
  Future<Result<ReturnPromptState>> load() async {
    try {
      return Success((
        firstOpenDay: _prefs.getString(_firstOpenDayKey),
        prompted: _prefs.getBool(_promptedKey) ?? false,
      ));
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать запрос уведомлений',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> save(ReturnPromptState state) async {
    try {
      if (state.firstOpenDay case final day?) {
        await requirePreferenceWrite(_prefs.setString(_firstOpenDayKey, day));
      }
      await requirePreferenceWrite(
        _prefs.setBool(_promptedKey, state.prompted),
      );
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить запрос уведомлений',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
