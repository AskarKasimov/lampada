import '../../../daily_cards/domain/entities/day_card.dart';
import '../entities/planned_reminder.dart';

/// Час утреннего напоминания и вечернего «день ещё не открыт».
const morningHour = 9;
const eveningHour = 20;

// Планируем неделю: локальные уведомления не обновятся без запуска приложения.
const reminderHorizonDays = 7;

/// Выбирает предстоящие напоминания по времени и дневному прогрессу.
class PlanReminders {
  const PlanReminders();

  List<PlannedReminder> call({
    required DateTime now,
    required Set<CardType> readToday,
    required List<CardType> sections,
  }) {
    if (sections.isEmpty) return const [];

    final unread = sections.where((s) => !readToday.contains(s)).toList();
    final plan = <PlannedReminder>[];

    // Сегодня ставим только ещё не прошедшие слоты.
    if (unread.isNotEmpty) {
      final morning = _at(now, 0, morningHour);
      if (morning.isAfter(now)) {
        plan.add(_reminderFor(id: 0, at: morning, section: unread.first));
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
    }

    // В будущие дни прогресс пуст, поэтому нужен только утренний слот.
    for (var day = 1; day <= reminderHorizonDays; day++) {
      plan.add(
        _reminderFor(
          id: 1 + day,
          at: _at(now, day, morningHour),
          section: sections.first,
        ),
      );
    }

    return plan;
  }

  static PlannedReminder _reminderFor({
    required int id,
    required DateTime at,
    required CardType section,
  }) {
    // Неизвестный тип использует цитату — она существует для каждого дня.
    final text = reminderTexts[section] ?? reminderTexts[CardType.quote]!;
    return PlannedReminder(id: id, at: at, title: text.title, body: text.body);
  }

  // Конструктор DateTime сохраняет локальную календарную арифметику при DST.
  static DateTime _at(DateTime now, int dayOffset, int hour) =>
      DateTime(now.year, now.month, now.day + dayOffset, hour);
}
