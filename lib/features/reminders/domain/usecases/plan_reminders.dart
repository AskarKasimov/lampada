import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/domain/entities/day_section.dart';
import '../entities/planned_reminder.dart';

/// Час утреннего напоминания и вечернего «день ещё не открыт».
const morningHour = 9;
const eveningHour = 20;

/// Через сколько после «Мудрости дня» звать к святому и к курсу.
const storyDelay = Duration(hours: 2);
const courseDelay = Duration(hours: 4);

/// Позже этого часа дневные напоминания не шлём: человек уже отдыхает.
const latestHour = 21;

/// Идентификаторы дневных слотов: 0 и 1 — утро и вечер, 2–8 — неделя вперёд.
const _storyId = 9;
const _courseId = 10;

/// Слот напоминания: утро (сегодня и неделя вперёд), вечер или днём после
/// «Мудрости дня».
enum PlannedSlot { morning, evening, afterWisdom }

/// Слот по идентификатору: из нажатого уведомления приходит только id.
/// Неизвестный id (расписание старой версии) считаем утренним.
PlannedSlot slotOfReminderId(int? id) => switch (id) {
  1 => PlannedSlot.evening,
  _storyId || _courseId => PlannedSlot.afterWisdom,
  _ => PlannedSlot.morning,
};

/// Какие дневные напоминания план ставит на сегодня; null, если никаких.
({bool story, bool course})? daytimeRemindersOf(
  List<PlannedReminder> plan,
  DateTime now,
) {
  bool has(int id) => plan.any(
    (r) =>
        r.id == id &&
        r.at.year == now.year &&
        r.at.month == now.month &&
        r.at.day == now.day,
  );
  final story = has(_storyId);
  final course = has(_courseId);
  return story || course ? (story: story, course: course) : null;
}

// Планируем неделю: локальные уведомления не обновятся без запуска приложения.
const reminderHorizonDays = 7;

/// Выбирает предстоящие напоминания по времени и дневному прогрессу.
class PlanReminders {
  const PlanReminders();

  /// [wisdomCompletedAt] — когда сегодня дочитана «Мудрость дня»; от него
  /// отсчитываются напоминания о святом ([storyTitle], если у дня есть
  /// рассказ) и о курсе. Будущие дни знают только утро: их прогресс ещё пуст.
  List<PlannedReminder> call({
    required DateTime now,
    required Set<CardType> readToday,
    required List<CardType> sections,
    DateTime? wisdomCompletedAt,
    String? storyTitle,
    bool storyRead = false,
    bool courseAvailable = true,
  }) {
    if (sections.isEmpty) return const [];

    final plan = <PlannedReminder>[];

    if (wisdomCompletedAt == null) {
      final morning = _at(now, 0, morningHour);
      if (morning.isAfter(now)) {
        plan.add(_morning(id: 0, at: morning));
      }

      final evening = _at(now, 0, eveningHour);
      // Вечернее напоминание только для дня без единого открытия.
      if (evening.isAfter(now) && readToday.isEmpty) {
        plan.add(
          PlannedReminder(
            id: 1,
            at: evening,
            title: untouchedDayReminder.title,
            body: untouchedDayReminder.body,
          ),
        );
      }
    } else {
      final latest = _at(wisdomCompletedAt, 0, latestHour);
      bool fits(DateTime at) => at.isAfter(now) && !at.isAfter(latest);

      final storyAt = wisdomCompletedAt.add(storyDelay);
      if (storyTitle != null &&
          storyTitle.trim().isNotEmpty &&
          !storyRead &&
          fits(storyAt)) {
        final text = storyReminder(storyTitle.trim());
        plan.add(
          PlannedReminder(
            id: _storyId,
            at: storyAt,
            title: text.title,
            body: text.body,
            section: DaySection.story,
          ),
        );
      }

      final courseAt = wisdomCompletedAt.add(courseDelay);
      if (courseAvailable &&
          !readToday.contains(CardType.basics) &&
          fits(courseAt)) {
        plan.add(
          PlannedReminder(
            id: _courseId,
            at: courseAt,
            title: courseReminder.title,
            body: courseReminder.body,
            section: DaySection.course,
          ),
        );
      }
    }

    // В будущие дни прогресс пуст, поэтому нужен только утренний слот.
    for (var day = 1; day <= reminderHorizonDays; day++) {
      plan.add(_morning(id: 1 + day, at: _at(now, day, morningHour)));
    }

    return plan;
  }

  static PlannedReminder _morning({required int id, required DateTime at}) {
    final text = morningReminders[_dayNumber(at) % morningReminders.length];
    return PlannedReminder(id: id, at: at, title: text.title, body: text.body);
  }

  /// Номер календарного дня: текст зависит от даты, а не от того, когда
  /// расписание пересобрали. UTC-полночь не сдвигается переходом на летнее
  /// время, в отличие от разницы локальных дат.
  static int _dayNumber(DateTime at) =>
      DateTime.utc(at.year, at.month, at.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  // Конструктор DateTime сохраняет локальную календарную арифметику при DST.
  static DateTime _at(DateTime now, int dayOffset, int hour) =>
      DateTime(now.year, now.month, now.day + dayOffset, hour);
}
