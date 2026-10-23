import 'analytics_event.dart';

/// Отправка продуктовых событий. Вызывается только из presentation:
/// domain остаётся чистым Dart.
abstract interface class Analytics {
  void log(AnalyticsEvent event);

  /// Обезличенные атрибуты профиля для сегментации отчётов.
  void setProfile(AnalyticsProfile profile);
}

/// Атрибуты профиля; null — значение пока неизвестно и не отправляется.
class AnalyticsProfile {
  const AnalyticsProfile({
    this.notificationsEnabled,
    this.notificationsPermitted,
    this.streak,
    this.wisdomDaysTotal,
    this.courseTopicsCompleted,
    this.bibleChaptersRead,
    this.bookmarksCount,
    this.theme,
  });

  final bool? notificationsEnabled;

  /// Разрешение ОС: юзер мог выключить уведомления мимо приложения.
  final bool? notificationsPermitted;
  final int? streak;
  final int? wisdomDaysTotal;
  final int? courseTopicsCompleted;
  final int? bibleChaptersRead;
  final int? bookmarksCount;
  final String? theme;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsProfile &&
      other.notificationsEnabled == notificationsEnabled &&
      other.notificationsPermitted == notificationsPermitted &&
      other.streak == streak &&
      other.wisdomDaysTotal == wisdomDaysTotal &&
      other.courseTopicsCompleted == courseTopicsCompleted &&
      other.bibleChaptersRead == bibleChaptersRead &&
      other.bookmarksCount == bookmarksCount &&
      other.theme == theme;

  @override
  int get hashCode => Object.hash(
    notificationsEnabled,
    notificationsPermitted,
    streak,
    wisdomDaysTotal,
    courseTopicsCompleted,
    bibleChaptersRead,
    bookmarksCount,
    theme,
  );
}
