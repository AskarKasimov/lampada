import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../result/result.dart';
import '../storage/preference_write.dart';
import 'theme_mode_repository.dart';

class PrefsThemeModeRepository implements ThemeModeRepository {
  PrefsThemeModeRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'theme_mode';

  @override
  Result<ThemeMode> load() {
    try {
      return Success(switch (_prefs.getString(_key)) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      });
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось загрузить тему',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> save(ThemeMode mode) async {
    try {
      await requirePreferenceWrite(_prefs.setString(_key, mode.name));
      return const Success(null);
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить тему',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
