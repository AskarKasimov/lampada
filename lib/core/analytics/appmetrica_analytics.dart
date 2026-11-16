import 'dart:async';

import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';

import 'activation_gate.dart';
import 'analytics.dart';
import 'analytics_event.dart';
import 'tracking_consent.dart';

/// Аналитика через AppMetrica. Ошибки SDK глотаем: событие не стоит
/// упавшего экрана, а в тестах нативной части нет вовсе.
class AppMetricaAnalytics implements Analytics {
  const AppMetricaAnalytics();

  /// События, отправленные до активации SDK, ждут её здесь: на первом
  /// запуске iOS активация стоит за ответом на запрос трекинга.
  static final _gate = ActivationGate();

  /// Запускает SDK. На iOS сначала спрашивает разрешение на трекинг: событие
  /// установки уходит при активации, и без ответа в нём не будет IDFA для
  /// атрибуции рекламы. Таймаут страхует запуск в фоне, когда окно не
  /// появится: тогда SDK стартует без IDFA, но события не застрянут.
  /// На Android рекламный идентификатор не собираем (AD_ID вырезан из
  /// манифеста).
  static Future<void> activate(String apiKey) async {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    try {
      if (isIOS) {
        await const TrackingConsent().request().timeout(
          const Duration(minutes: 1),
          onTimeout: () => TrackingStatus.notDetermined,
        );
      }
      await AppMetrica.activate(
        AppMetricaConfig(
          apiKey,
          locationTracking: false,
          advIdentifiersTracking: isIOS,
          logs: kDebugMode,
        ),
      );
    } finally {
      _gate.open();
    }
  }

  @override
  void log(AnalyticsEvent event) {
    if (kDebugMode) debugPrint('[analytics] $event');
    _send(
      () => event.params.isEmpty
          ? AppMetrica.reportEvent(event.name)
          : AppMetrica.reportEventWithMap(event.name, event.params),
    );
  }

  @override
  void setProfile(AnalyticsProfile profile) {
    // Тип атрибута плагин не экспортирует: список типизирует конструктор.
    final userProfile = AppMetricaUserProfile([
      if (profile.notificationsEnabled case final value?)
        AppMetricaBooleanAttribute.withValue('notifications_enabled', value),
      if (profile.notificationsPermitted case final value?)
        AppMetricaNotificationEnabledAttribute.withValue(value),
      if (profile.streak case final value?) _number('streak', value),
      if (profile.wisdomDaysTotal case final value?)
        _number('wisdom_days_total', value),
      if (profile.courseTopicsCompleted case final value?)
        _number('course_topics_completed', value),
      if (profile.bibleChaptersRead case final value?)
        _number('bible_chapters_read', value),
      if (profile.bookmarksCount case final value?)
        _number('bookmarks_count', value),
      if (profile.theme case final value?)
        AppMetricaStringAttribute.withValue('theme', value),
    ]);
    if (userProfile.attributes.isEmpty) return;
    _send(() => AppMetrica.reportUserProfile(userProfile));
  }

  static AppMetricaNumberAttribute _number(String key, int value) =>
      AppMetricaNumberAttribute.withValue(key, value.toDouble());

  static void _send(Future<void> Function() call) => _gate.run(
    () => unawaited(
      call().catchError((Object e) {
        if (kDebugMode) debugPrint('[analytics] не отправлено: $e');
      }),
    ),
  );
}
