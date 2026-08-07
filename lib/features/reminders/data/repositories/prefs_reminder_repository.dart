import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../domain/repositories/reminder_repository.dart';

/// Настройка напоминаний в shared_preferences: два флага, JSON не нужен.
class PrefsReminderRepository implements ReminderRepository {
  PrefsReminderRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _enabledKey = 'reminders_enabled';
  static const _askedKey = 'reminders_asked';

  @override
  Future<Result<ReminderSettings>> load() async => _guard(
    () async => ReminderSettings(
      enabled: _prefs.getBool(_enabledKey) ?? false,
      asked: _prefs.getBool(_askedKey) ?? false,
    ),
  );

  @override
  Future<Result<ReminderSettings>> save(ReminderSettings settings) async =>
      _guard(() async {
        await _prefs.setBool(_enabledKey, settings.enabled);
        await _prefs.setBool(_askedKey, settings.asked);
        return settings;
      });

  Future<Result<ReminderSettings>> _guard(
    Future<ReminderSettings> Function() op,
  ) async {
    try {
      return Success(await op());
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать настройку напоминаний',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
