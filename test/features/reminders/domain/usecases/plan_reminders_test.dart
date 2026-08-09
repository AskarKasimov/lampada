import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/reminders/domain/entities/planned_reminder.dart';
import 'package:lampada/features/reminders/domain/usecases/plan_reminders.dart';

const _plan = PlanReminders();

const _sections = [
  CardType.quote,
  CardType.advice,
  CardType.parable,
  CardType.reading,
  CardType.basics,
];

/// Раннее утро: оба сегодняшних слота ещё впереди.
final _earlyMorning = DateTime(2026, 8, 6, 7);

List<PlannedReminder> today(List<PlannedReminder> plan, DateTime now) =>
    plan.where((r) => r.at.day == now.day).toList();

void main() {
  test('утреннее напоминание называет первый непрочитанный раздел', () {
    final plan = _plan(
      now: _earlyMorning,
      readToday: {CardType.quote, CardType.advice},
      sections: _sections,
    );

    final morning = today(plan, _earlyMorning).first;
    expect(morning.title, reminderTexts[CardType.parable]!.title);
  });

  test('всё прочитано — сегодня не напоминаем вовсе', () {
    final plan = _plan(
      now: _earlyMorning,
      readToday: _sections.toSet(),
      sections: _sections,
    );

    expect(today(plan, _earlyMorning), isEmpty);
    // На завтра напоминание остаётся: прогресс к тому времени обнулится.
    expect(plan, isNotEmpty);
  });

  test('вечернее шлём только когда за день не открыли ничего', () {
    final untouched = _plan(
      now: _earlyMorning,
      readToday: const {},
      sections: _sections,
    );
    expect(
      today(untouched, _earlyMorning).map((r) => r.title),
      contains(untouchedDayReminder.title),
    );

    // Прочитал хотя бы одно — добивать вторым напоминанием незачем.
    final started = _plan(
      now: _earlyMorning,
      readToday: {CardType.quote},
      sections: _sections,
    );
    expect(
      started.map((r) => r.title),
      isNot(contains(untouchedDayReminder.title)),
    );
  });

  test('прошедшие слоты сегодня не планируются', () {
    // 21:00 — оба слота позади.
    final late = DateTime(2026, 8, 6, 21);
    final plan = _plan(now: late, readToday: const {}, sections: _sections);

    expect(today(plan, late), isEmpty);
  });

  test('на будущие дни ставим цитату: прогресс обнулится', () {
    final plan = _plan(
      now: _earlyMorning,
      readToday: {CardType.quote, CardType.advice},
      sections: _sections,
    );

    final tomorrow = plan.firstWhere((r) => r.at.day == 7);
    expect(tomorrow.title, reminderTexts[CardType.quote]!.title);
    expect(tomorrow.at.hour, morningHour);
  });

  test('горизонт планирования ограничен неделей', () {
    final plan = _plan(
      now: _earlyMorning,
      readToday: const {},
      sections: _sections,
    );

    final future = plan.where((r) => r.at.day != _earlyMorning.day);
    expect(future, hasLength(reminderHorizonDays));
  });

  test('идентификаторы уникальны — иначе напоминания затрут друг друга', () {
    final plan = _plan(
      now: _earlyMorning,
      readToday: const {},
      sections: _sections,
    );

    expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
  });

  test('пустой день не планирует ничего', () {
    expect(
      _plan(now: _earlyMorning, readToday: const {}, sections: const []),
      isEmpty,
    );
  });

  test('ни в одном тексте нет восклицания и упрёка', () {
    // §7 требований прямо запрещает давить виной — это главный отталкивающий
    // фактор для персоны.
    final all = [
      ...reminderTexts.values,
      (title: untouchedDayReminder.title, body: untouchedDayReminder.body),
    ];
    for (final text in all) {
      expect('${text.title} ${text.body}', isNot(contains('!')));
      expect(
        '${text.title} ${text.body}'.toLowerCase(),
        isNot(contains('пропустил')),
      );
    }
  });
}
