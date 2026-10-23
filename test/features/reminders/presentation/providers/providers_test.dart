import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/reminders/data/services/notification_service.dart';
import 'package:lampada/features/reminders/domain/entities/planned_reminder.dart';
import 'package:lampada/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:lampada/features/reminders/presentation/providers/providers.dart';

import '../../../../support/fake_analytics.dart';

class _RejectingReminderRepository implements ReminderRepository {
  @override
  Future<Result<ReminderSettings>> load() async =>
      const Success(ReminderSettings.initial);

  @override
  Future<Result<ReminderSettings>> save(ReminderSettings settings) async =>
      Failure(
        AppFailure('Не удалось сохранить настройку', kind: FailureKind.unknown),
      );
}

class _SavingReminderRepository implements ReminderRepository {
  var saved = ReminderSettings.initial;

  @override
  Future<Result<ReminderSettings>> load() async => Success(saved);

  @override
  Future<Result<ReminderSettings>> save(ReminderSettings settings) async {
    saved = settings;
    return Success(settings);
  }
}

class _GrantingNotificationService implements NotificationService {
  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> init({void Function(NotificationTap tap)? onTap}) async {}

  @override
  Future<bool> isPermitted() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {}
}

class _DenyingNotificationService extends _GrantingNotificationService {
  @override
  Future<bool> requestPermission() async => false;
}

void main() {
  test('не включает напоминания, если настройка не сохранилась', () async {
    final container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(
          _RejectingReminderRepository(),
        ),
        notificationServiceProvider.overrideWithValue(
          _GrantingNotificationService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(reminderSettingsProvider.future);

    final enabled = await container
        .read(reminderSettingsProvider.notifier)
        .requestAndEnable();

    expect(enabled, isFalse);
    final settings = container.read(reminderSettingsProvider).value!;
    expect(settings.enabled, isFalse);
    expect(settings.asked, isFalse);
  });

  test('запоминает отказ в системном разрешении', () async {
    final repository = _SavingReminderRepository();
    final container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(
          _DenyingNotificationService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(reminderSettingsProvider.future);

    final enabled = await container
        .read(reminderSettingsProvider.notifier)
        .requestAndEnable();

    expect(enabled, isFalse);
    expect(repository.saved.enabled, isFalse);
    expect(repository.saved.asked, isTrue);
  });

  group('переключатель в профиле', () {
    Future<FakeAnalytics> toggle({
      required bool enabled,
      NotificationService? service,
    }) async {
      final analytics = FakeAnalytics();
      final container = ProviderContainer(
        overrides: [
          reminderRepositoryProvider.overrideWithValue(
            _SavingReminderRepository(),
          ),
          notificationServiceProvider.overrideWithValue(
            service ?? _GrantingNotificationService(),
          ),
          analyticsProvider.overrideWithValue(analytics),
        ],
      );
      addTearDown(container.dispose);
      await container.read(reminderSettingsProvider.future);
      await container
          .read(reminderSettingsProvider.notifier)
          .setEnabled(enabled: enabled);
      return analytics;
    }

    test('включение пишет ответ системы', () async {
      final analytics = await toggle(
        enabled: true,
        service: _DenyingNotificationService(),
      );

      expect(analytics.single('reminders_toggled'), {
        'enabled': true,
        'os_granted': false,
      });
    });

    test('выключение пишется без запроса к системе', () async {
      final analytics = await toggle(enabled: false);

      expect(analytics.single('reminders_toggled'), {'enabled': false});
    });
  });
}
