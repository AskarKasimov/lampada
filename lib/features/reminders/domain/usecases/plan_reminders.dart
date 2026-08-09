import '../../../daily_cards/domain/entities/day_card.dart';
import '../entities/planned_reminder.dart';

/// Час утреннего напоминания и вечернего «день ещё не открыт».
const morningHour = 9;
const eveningHour = 20;

/// На сколько дней вперёд планируем. Локальные уведомления живут в системе
/// и без запуска приложения не обновляются: неделя — это запас на случай,
/// если юзер не заходил, и одновременно естественный предел. Не открывал
/// восемь дней — напоминания тихо кончились, и это правильно: дожимать
/// того, кто ушёл, приложение не должно.
const reminderHorizonDays = 7;

/// Считает, какие напоминания должны стоять в системе прямо сейчас.
///
/// Чистая функция от времени и прогресса — вся логика «о чём напоминать»
/// проверяется тестами без симулятора и без разрешений.
///
/// Правила:
/// * напоминаем только о НЕПРОЧИТАННЫХ разделах, поэтому текст называет
///   первый, до которого юзер не дошёл;
/// * всё прочитано — сегодня молчим совсем;
/// * вечернее шлём только если за день не открыли ничего;
/// * на будущие дни ставим только утреннее: к тому времени прогресс
///   обнулится и непрочитанным будет всё, начиная с цитаты.
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

    // Сегодня: только слоты, которые ещё не прошли, и только если осталось
    // что показать.
    if (unread.isNotEmpty) {
      final morning = _at(now, 0, morningHour);
      if (morning.isAfter(now)) {
        plan.add(_reminderFor(id: 0, at: morning, section: unread.first));
      }

      final evening = _at(now, 0, eveningHour);
      // Вечернее — только для нетронутого дня. Если юзер что-то читал,
      // добивать его вторым напоминанием незачем.
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

    // Будущие дни: прогресс обнулится, непрочитан будет весь день.
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
    // Незнакомый тип не должен ронять планирование — подписываем цитатой,
    // она есть в дне всегда.
    final text = reminderTexts[section] ?? reminderTexts[CardType.quote]!;
    return PlannedReminder(id: id, at: at, title: text.title, body: text.body);
  }

  /// [DateTime] с локальной арифметикой дат: перевод часов и разная длина
  /// суток обрабатываются конструктором, а не прибавлением 24 часов.
  static DateTime _at(DateTime now, int dayOffset, int hour) =>
      DateTime(now.year, now.month, now.day + dayOffset, hour);
}
