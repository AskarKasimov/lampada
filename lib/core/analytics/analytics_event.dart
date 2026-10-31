import '../result/result.dart';

/// Каталог событий аналитики. Имена и допустимые значения живут только
/// здесь, чтобы строки не расходились по коду; карта событий с вопросами,
/// на которые они отвечают, лежит в docs/superpowers/specs.
///
/// Правила: имена `объект_действие` в snake_case, без текста контента, URL и
/// дат; дату передаём сдвигом от сегодня (`day_offset`).
class AnalyticsEvent {
  AnalyticsEvent._(this.name, [Map<String, Object?> params = const {}])
    : params = {
        for (final MapEntry(:key, :value) in params.entries)
          if (value != null) key: value is Enum ? _snake(value.name) : value,
      };

  final String name;
  final Map<String, Object> params;

  // Онбординг.
  factory AnalyticsEvent.onboardingStepViewed(OnboardingStep step) =>
      AnalyticsEvent._('onboarding_step_viewed', {'step': step});
  factory AnalyticsEvent.onboardingCompleted() =>
      AnalyticsEvent._('onboarding_completed');
  factory AnalyticsEvent.onboardingVideoFailed() =>
      AnalyticsEvent._('onboarding_video_failed');

  // Лампада.
  factory AnalyticsEvent.lampLit({
    required LampSource source,
    required int streak,
    required bool restarted,
  }) => AnalyticsEvent._('lamp_lit', {
    'source': source,
    'streak': streak,
    'restarted': restarted,
  });

  // Мудрость дня.
  factory AnalyticsEvent.wisdomOpened({
    required OpenSource source,
    required int dayOffset,
    required int cardsTotal,
    required bool resumed,
    required bool alreadyCompleted,
  }) => AnalyticsEvent._('wisdom_opened', {
    'source': source,
    'day_offset': dayOffset,
    'cards_total': cardsTotal,
    'resumed': resumed,
    'already_completed': alreadyCompleted,
  });
  factory AnalyticsEvent.wisdomCompleted({
    required int dayOffset,
    required bool countsStreak,
    required int lifetimeDays,
  }) => AnalyticsEvent._('wisdom_completed', {
    'day_offset': dayOffset,
    'counts_streak': countsStreak,
    'lifetime_days': lifetimeDays,
  });
  factory AnalyticsEvent.wisdomClosed({
    required int dayOffset,
    required int pagesSeen,
    required int pagesTotal,
    required bool completed,
  }) => AnalyticsEvent._('wisdom_closed', {
    'day_offset': dayOffset,
    'pages_seen': pagesSeen,
    'pages_total': pagesTotal,
    'completed': completed,
  });
  factory AnalyticsEvent.cardRead({
    required String cardType,
    required int dayOffset,
  }) => AnalyticsEvent._('card_read', {
    'card_type': cardType,
    'day_offset': dayOffset,
  });
  factory AnalyticsEvent.summaryChapterOpened({required bool auto}) =>
      AnalyticsEvent._('summary_chapter_opened', {'auto': auto});
  factory AnalyticsEvent.interpretationOpened() =>
      AnalyticsEvent._('interpretation_opened');
  factory AnalyticsEvent.fullTextOpened(String content) =>
      AnalyticsEvent._('full_text_opened', {'content': content});

  // Основы веры.
  factory AnalyticsEvent.courseOpened({
    required OpenSource source,
    required int topic,
    required bool firstTime,
  }) => AnalyticsEvent._('course_opened', {
    'source': source,
    'topic': topic,
    'first_time': firstTime,
  });
  factory AnalyticsEvent.courseTopicCompleted({
    required int topic,
    required int topicsCompleted,
  }) => AnalyticsEvent._('course_topic_completed', {
    'topic': topic,
    'topics_completed': topicsCompleted,
  });
  factory AnalyticsEvent.courseFinished() =>
      AnalyticsEvent._('course_finished');
  factory AnalyticsEvent.courseInfoOpened(CourseInfoScreen screen) =>
      AnalyticsEvent._('course_info_opened', {'screen': screen});

  // Память дня.
  factory AnalyticsEvent.storyOpened({
    required OpenSource source,
    required int dayOffset,
    required bool hasIcon,
  }) => AnalyticsEvent._('story_opened', {
    'source': source,
    'day_offset': dayOffset,
    'has_icon': hasIcon,
  });
  factory AnalyticsEvent.storyClosed({
    required int pagesSeen,
    required int pagesTotal,
    required bool finished,
  }) => AnalyticsEvent._('story_closed', {
    'pages_seen': pagesSeen,
    'pages_total': pagesTotal,
    'finished': finished,
  });

  // Главная и навигация.
  factory AnalyticsEvent.tabOpened(AnalyticsTab tab) =>
      AnalyticsEvent._('tab_opened', {'tab': tab});

  // Библия.
  factory AnalyticsEvent.bibleChapterOpened({
    required String book,
    required int chapter,
    required BibleOpenSource source,
  }) => AnalyticsEvent._('bible_chapter_opened', {
    'book': book,
    'chapter': chapter,
    'source': source,
  });
  factory AnalyticsEvent.bibleChapterCompleted({
    required String book,
    required int chapter,
  }) => AnalyticsEvent._('bible_chapter_completed', {
    'book': book,
    'chapter': chapter,
  });

  // Закладки.
  factory AnalyticsEvent.bookmarkAdded({
    required String kind,
    String? content,
  }) => AnalyticsEvent._('bookmark_added', {'kind': kind, 'content': content});
  factory AnalyticsEvent.bookmarkRemoved({
    required String kind,
    required BookmarkPlacement placement,
  }) => AnalyticsEvent._('bookmark_removed', {
    'kind': kind,
    'placement': placement,
  });
  factory AnalyticsEvent.bookmarksOpened({required int count}) =>
      AnalyticsEvent._('bookmarks_opened', {'count': count});
  factory AnalyticsEvent.bookmarkOpened({required String kind}) =>
      AnalyticsEvent._('bookmark_opened', {'kind': kind});

  // Поделиться.
  factory AnalyticsEvent.contentShared({
    required SharedContent content,
    required ShareMethod method,
    required ShareOutcome result,
  }) => AnalyticsEvent._('content_shared', {
    'content': content,
    'method': method,
    'result': result,
  });

  // Напоминания.
  factory AnalyticsEvent.reminderPromptShown(ReminderPromptTrigger trigger) =>
      AnalyticsEvent._('reminder_prompt_shown', {'trigger': trigger});
  factory AnalyticsEvent.reminderPromptAnswered({
    required ReminderPromptChoice choice,
    bool? osGranted,
  }) => AnalyticsEvent._('reminder_prompt_answered', {
    'choice': choice,
    'os_granted': osGranted,
  });
  factory AnalyticsEvent.notificationOpened({
    required AnalyticsSection section,
    required ReminderSlot slot,
    required bool coldStart,
  }) => AnalyticsEvent._('notification_opened', {
    'section': section,
    'slot': slot,
    'cold_start': coldStart,
  });
  factory AnalyticsEvent.daytimeRemindersScheduled({
    required bool story,
    required bool course,
  }) => AnalyticsEvent._('daytime_reminders_scheduled', {
    'story': story,
    'course': course,
  });
  factory AnalyticsEvent.remindersToggled({
    required bool enabled,
    bool? osGranted,
  }) => AnalyticsEvent._('reminders_toggled', {
    'enabled': enabled,
    'os_granted': osGranted,
  });

  // Профиль.
  factory AnalyticsEvent.reviewRequested(ReviewTrigger trigger) =>
      AnalyticsEvent._('review_requested', {'trigger': trigger});
  factory AnalyticsEvent.themeChanged(String theme) =>
      AnalyticsEvent._('theme_changed', {'theme': theme});

  // Ошибки контента.
  factory AnalyticsEvent.contentLoadFailed({
    required LoadedContent content,
    required String kind,
  }) => AnalyticsEvent._('content_load_failed', {
    'content': content,
    'kind': kind,
  });
  factory AnalyticsEvent.contentRetryTapped(LoadedContent content) =>
      AnalyticsEvent._('content_retry_tapped', {'content': content});

  @override
  String toString() => '$name $params';
}

/// Вид сбоя для `content_load_failed`: у [AppFailure] он есть, остальное
/// считаем неизвестным.
String failureKindOf(Object? error) =>
    error is AppFailure ? error.kind.name : FailureKind.unknown.name;

String _snake(String camel) =>
    camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

enum OnboardingStep { time, reader }

enum OpenSource { tile, onboarding, notification }

enum LampSource { wisdom, course }

/// Раздел дня; повторяет `DaySection`, но core не зависит от фич.
enum AnalyticsSection { wisdom, story, course }

enum ReminderSlot { morning, evening, afterWisdom }

enum ReminderPromptTrigger { wisdom, course }

enum ReminderPromptChoice { allow, later, dismissed }

enum AnalyticsTab { home, bible, profile }

enum BibleOpenSource {
  firstOpen,
  tab,
  catalog,
  next,
  dailyReading,
  bookmark,
  verseOfDay,
}

enum BookmarkPlacement { reader, listSwipe, detail }

enum SharedContent {
  quote,
  advice,
  parable,
  reading,
  basics,
  bibleVerse,
  interpretation,
  story,
  bookmark,
  app,
}

enum ShareMethod { button, selection }

enum ShareOutcome { success, dismissed, unavailable }

enum ReviewTrigger { profile, firstCompletion }

enum CourseInfoScreen { courseDetail, contents }

enum LoadedContent { day, gospel, story, courseTopic, bibleChapter }
