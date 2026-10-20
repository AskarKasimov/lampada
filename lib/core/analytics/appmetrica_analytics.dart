import 'dart:async';

import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';

import 'analytics.dart';
import 'analytics_event.dart';

/// Аналитика через AppMetrica. Ошибки SDK глотаем: событие не стоит
/// упавшего экрана, а в тестах нативной части нет вовсе.
class AppMetricaAnalytics implements Analytics {
  const AppMetricaAnalytics();

  @override
  void log(AnalyticsEvent event) {
    if (kDebugMode) debugPrint('[analytics] $event');
    _send(
      event.params.isEmpty
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
    _send(AppMetrica.reportUserProfile(userProfile));
  }

  static AppMetricaNumberAttribute _number(String key, int value) =>
      AppMetricaNumberAttribute.withValue(key, value.toDouble());

  static void _send(Future<void> call) => unawaited(
    call.catchError((Object e) {
      if (kDebugMode) debugPrint('[analytics] не отправлено: $e');
    }),
  );
}
