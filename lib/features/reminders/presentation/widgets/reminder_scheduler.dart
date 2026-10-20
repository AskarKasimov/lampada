import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/format/date_key.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../daily_cards/domain/course_calendar.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../../../day_story/presentation/providers/providers.dart';
import '../../domain/entities/planned_reminder.dart';
import '../../domain/usecases/plan_reminders.dart';
import '../providers/providers.dart';

/// Держит системное расписание напоминаний в согласии с прогрессом.
///
/// Пересчитывает при каждом изменении прочитанного и состава дня: напоминаем
/// только о том, до чего юзер не дошёл, поэтому прочитанная карточка обязана
/// снимать своё напоминание сразу, а не завтра. Локальные уведомления живут
/// в системе и сами о прогрессе не знают.
class ReminderScheduler extends ConsumerStatefulWidget {
  const ReminderScheduler({
    required this.child,
    super.key,
    this.clock = DateTime.now,
  });

  final Widget child;

  /// Подменяется в тестах: дневные слоты зависят от времени суток.
  final DateTime Function() clock;

  @override
  ConsumerState<ReminderScheduler> createState() => _ReminderSchedulerState();
}

class _ReminderSchedulerState extends ConsumerState<ReminderScheduler> {
  /// Последнее отправленное в систему расписание — чтобы не дёргать плагин
  /// на каждый ребилд с тем же результатом.
  String? _lastPlan;

  Future<void> _reschedule() async {
    final settings = ref.read(reminderSettingsProvider).value;
    final service = ref.read(notificationServiceProvider);

    if (settings == null || !settings.enabled) {
      if (_lastPlan != null) {
        _lastPlan = null;
        await service.cancelAll();
      }
      return;
    }

    final day = ref.read(todayCardsProvider).value;
    final progress = ref.read(dayProgressProvider).value;
    if (day == null || progress == null) return;

    final now = widget.clock();
    final storyRead =
        ref.read(readStoryDaysProvider).value?.contains(dateKey(now)) ?? false;
    final completedTopics = ref.read(completedCourseTopicsProvider).value;
    final plan = planReminders(
      now: now,
      readToday: progress.readTypes,
      sections: day.cards.map((c) => c.type).toList(),
      wisdomCompletedAt: progress.wisdomCompletedAt,
      // Без ссылки рассказа не открыть: звать к нему незачем.
      storyTitle: day.storyUrl == null ? null : day.title,
      storyRead: storyRead,
      courseAvailable:
          completedTopics == null || completedTopics.length < courseTopicCount,
    );

    final signature = plan
        .map((r) => '${r.id}@${r.at}:${r.section.name}:${r.title}')
        .join('|');
    if (signature == _lastPlan) return;
    _lastPlan = signature;
    await service.schedule(plan);
    _logDaytime(plan, now);
  }

  /// Ключ prefs с днём, за который событие уже отправлено: расписание
  /// пересобирается много раз за день и при каждом запуске.
  static const _daytimeLoggedKey = 'analytics_daytime_reminders_day';

  void _logDaytime(List<PlannedReminder> plan, DateTime now) {
    final daytime = daytimeRemindersOf(plan, now);
    if (daytime == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final today = dateKey(now);
    if (prefs.getString(_daytimeLoggedKey) == today) return;
    unawaited(prefs.setString(_daytimeLoggedKey, today));
    ref
        .read(analyticsProvider)
        .log(
          AnalyticsEvent.daytimeRemindersScheduled(
            story: daytime.story,
            course: daytime.course,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(dayProgressProvider, (_, _) => _reschedule())
      ..listen(todayCardsProvider, (_, _) => _reschedule())
      ..listen(reminderSettingsProvider, (_, _) => _reschedule())
      ..listen(readStoryDaysProvider, (_, _) => _reschedule())
      ..listen(completedCourseTopicsProvider, (_, _) => _reschedule());

    // Первый расчёт: слушатели срабатывают только на ИЗМЕНЕНИЯ, а к моменту
    // построения шелла и день, и прогресс обычно уже загружены сплэшем.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reschedule());

    return widget.child;
  }
}
