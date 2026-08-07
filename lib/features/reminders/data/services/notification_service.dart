import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/log/net_log.dart';
import '../../domain/entities/planned_reminder.dart';

/// Платформенная часть напоминаний. Всё знание про
/// `flutter_local_notifications` и часовые пояса заканчивается здесь —
/// выше по стеку живут только [PlannedReminder] и булевы флаги.
abstract interface class NotificationService {
  /// Готовит плагин к работе. Разрешения НЕ запрашивает: система показывает
  /// запрос один раз за установку, и потратить его на холодный старт значит
  /// потерять большинство согласий.
  Future<void> init({void Function()? onTap});

  /// Показывает системный запрос. true — разрешили.
  Future<bool> requestPermission();

  /// Разрешены ли уведомления сейчас. Юзер мог отключить их в Настройках
  /// iOS мимо приложения, и хранимый флаг об этом не знает.
  Future<bool> isPermitted();

  Future<void> schedule(List<PlannedReminder> reminders);

  Future<void> cancelAll();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channelId = 'daily_reminders';

  @override
  Future<void> init({void Function()? onTap}) async {
    if (_ready) return;

    tz_data.initializeTimeZones();
    // Без явной установки зоны `tz.local` остаётся UTC, и напоминание,
    // назначенное на 9 утра, приходило бы в полночь по Москве.
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Exception catch (e) {
      netLog('часовой пояс не определился, остаёмся на UTC: $e');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) => onTap?.call(),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> isPermitted() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.checkPermissions();
      return granted?.isAlertEnabled ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    await cancelAll();
    for (final r in reminders) {
      final at = tz.TZDateTime.from(r.at, tz.local);
      // Прошедшее время система молча проглатывает — не отправляем вовсе,
      // чтобы в логе было видно реальное расписание.
      if (!at.isAfter(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: at,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            _channelId,
            'Напоминания',
            channelDescription: 'Тихое напоминание о непрочитанном за день',
            importance: Importance.defaultImportance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    netLog('напоминаний запланировано: ${reminders.length}');
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
