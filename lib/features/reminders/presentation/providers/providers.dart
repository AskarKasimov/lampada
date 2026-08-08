// Единственное место, где presentation фичи видит data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/repositories/prefs_reminder_repository.dart';
import '../../data/services/notification_service.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/plan_reminders.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => PrefsReminderRepository(ref.watch(sharedPreferencesProvider)),
);

const planReminders = PlanReminders();

/// Настройка напоминаний. Загружается один раз и живёт в состоянии: экран
/// запроса, Профиль и планировщик должны видеть одно и то же.
final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );

class ReminderSettingsNotifier extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() async {
    final result = await ref.read(reminderRepositoryProvider).load();
    return switch (result) {
      Success(value: final s) => s,
      // Сбой чтения настройки не должен ломать экран: считаем, что
      // напоминания выключены и мы ещё не спрашивали.
      Failure() => ReminderSettings.initial,
    };
  }

  /// Спрашивает разрешение у системы и запоминает исход.
  ///
  /// [asked] ставим в любом случае, даже при отказе: iOS больше не покажет
  /// системный запрос, и повторно предлагать его — обманывать.
  Future<bool> requestAndEnable() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    final saved = await _save(ReminderSettings(enabled: granted, asked: true));
    return granted && saved;
  }

  /// Отказ на нашем экране, без системного запроса. Разрешение остаётся
  /// непотраченным — включить можно позже из Профиля.
  Future<void> declineForNow() =>
      _save(const ReminderSettings(enabled: false, asked: true));

  Future<void> setEnabled({required bool enabled}) async {
    if (!enabled) {
      await ref.read(notificationServiceProvider).cancelAll();
      await _save(const ReminderSettings(enabled: false, asked: true));
      return;
    }
    await requestAndEnable();
  }

  Future<bool> _save(ReminderSettings settings) async {
    final result = await ref.read(reminderRepositoryProvider).save(settings);
    return switch (result) {
      Success() => () {
        state = AsyncData(settings);
        return true;
      }(),
      Failure() => false,
    };
  }
}
