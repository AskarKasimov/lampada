import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_section.dart';
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
  test('утро с непрочитанной мудростью берёт текст из утреннего набора', () {
    final plan = _plan(
      now: _earlyMorning,
      readToday: {CardType.quote, CardType.advice},
      sections: _sections,
    );

    final morning = today(plan, _earlyMorning).first;
    expect(morningReminders.map((r) => r.title), contains(morning.title));
  });

  test('всё прочитано — сегодня не напоминаем вовсе', () {
    final plan = _plan(
      now: _earlyMorning,
      readToday: _sections.toSet(),
      sections: _sections,
      wisdomCompletedAt: _earlyMorning,
      storyTitle: 'Святитель Николай',
      storyRead: true,
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

  test('утра недели не повторяют друг друга', () {
    // Раньше будущие дни брали первый раздел, и неделю подряд приходил
    // один и тот же текст.
    final plan = _plan(
      now: _earlyMorning,
      readToday: {CardType.quote, CardType.advice},
      sections: _sections,
    );

    final mornings = plan.where((r) => r.at.day != _earlyMorning.day);
    expect(mornings.every((r) => r.at.hour == morningHour), isTrue);
    expect(mornings.map((r) => r.title).toSet(), hasLength(mornings.length));
  });

  test('текст утра зависит от даты, а не от момента планирования', () {
    // Расписание пересобирается при каждом изменении прогресса: текст на
    // завтра не должен прыгать между пересборками.
    List<PlannedReminder> planAt(int hour) => _plan(
      now: DateTime(2026, 8, 6, hour),
      readToday: const {},
      sections: _sections,
    );
    String tomorrow(List<PlannedReminder> plan) =>
        plan.firstWhere((r) => r.at.day == 7).title;

    expect(tomorrow(planAt(6)), tomorrow(planAt(22)));
  });

  test(
    'утро дня не зависит от того, планировали его накануне или в сам день',
    () {
      final plan = _plan(
        now: DateTime(2026, 8, 7, 7),
        readToday: const {},
        sections: _sections,
      );
      final yesterdayPlan = _plan(
        now: _earlyMorning,
        readToday: const {},
        sections: _sections,
      );

      // Утро 7-го одинаково, планировали его 6-го или в сам день.
      expect(
        plan.firstWhere((r) => r.at.day == 7 && r.at.hour == morningHour).title,
        yesterdayPlan.firstWhere((r) => r.at.day == 7).title,
      );
    },
  );

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

  final allTexts = [
    ...morningReminders,
    courseReminder,
    untouchedDayReminder,
    storyReminder('Святитель Николай'),
  ].map((r) => '${r.title} ${r.body}');

  test('ни в одном тексте нет восклицания и упрёка', () {
    // Давить виной нельзя: это главный отталкивающий фактор для персоны.
    for (final text in allTexts) {
      expect(text, isNot(contains('!')));
      expect(text.toLowerCase(), isNot(contains('пропустил')));
      // «Ждёт» в каждом втором тексте звучало упрёком.
      expect(text.toLowerCase(), isNot(contains('ждёт')));
    }
  });

  test('все тексты обращаются на «вы», как остальное приложение', () {
    for (final text in allTexts) {
      final words = text.toLowerCase().split(RegExp(r'[^а-яё]+'));
      for (final informal in ['ты', 'тебя', 'тебе', 'твой', 'твоя']) {
        expect(words, isNot(contains(informal)), reason: text);
      }
    }
  });

  test('утренних текстов хватает на неделю без повторов', () {
    expect(
      morningReminders.map((r) => r.title).toSet().length,
      greaterThanOrEqualTo(reminderHorizonDays),
    );
  });

  group('после «Мудрости дня»', () {
    final completedAt = DateTime(2026, 8, 6, 10, 15);

    List<PlannedReminder> planAfter({
      DateTime? now,
      DateTime? completed,
      Set<CardType> readToday = const {},
      String? storyTitle = 'Святитель Николай Чудотворец',
      bool storyRead = false,
      bool courseAvailable = true,
    }) => _plan(
      now: now ?? completedAt,
      readToday: readToday,
      sections: _sections,
      wisdomCompletedAt: completed ?? completedAt,
      storyTitle: storyTitle,
      storyRead: storyRead,
      courseAvailable: courseAvailable,
    );

    PlannedReminder? of(List<PlannedReminder> plan, DaySection section) => plan
        .where((r) => r.at.day == completedAt.day && r.section == section)
        .firstOrNull;

    test('через два часа зовёт прочитать о святом дня', () {
      final story = of(planAfter(), DaySection.story);

      expect(story?.at, completedAt.add(const Duration(hours: 2)));
      expect(story?.title, contains('Святитель Николай Чудотворец'));
    });

    test('через четыре часа зовёт в тему «Основ веры»', () {
      final course = of(planAfter(), DaySection.course);

      expect(course?.at, completedAt.add(const Duration(hours: 4)));
      expect(course?.title, courseReminder.title);
    });

    test('утро и вечер о мудрости больше не нужны', () {
      final plan = planAfter(now: _earlyMorning);

      expect(of(plan, DaySection.wisdom), isNull);
    });

    test('прочитанный рассказ о святом не напоминаем', () {
      expect(of(planAfter(storyRead: true), DaySection.story), isNull);
    });

    test('без памяти дня напоминание о святом не планируем', () {
      expect(of(planAfter(storyTitle: null), DaySection.story), isNull);
    });

    test('пройденную сегодня тему курса не напоминаем', () {
      final plan = planAfter(readToday: {CardType.basics});

      expect(of(plan, DaySection.course), isNull);
    });

    test('пройденный целиком курс не напоминаем', () {
      expect(of(planAfter(courseAvailable: false), DaySection.course), isNull);
    });

    test('после 21:00 не беспокоим: поздние слоты отбрасываем', () {
      // 18:00 + 2 ч = 20:00 ещё можно, 18:00 + 4 ч = 22:00 уже нет.
      final plan = planAfter(
        now: DateTime(2026, 8, 6, 18),
        completed: DateTime(2026, 8, 6, 18),
      );

      expect(of(plan, DaySection.story), isNotNull);
      expect(of(plan, DaySection.course), isNull);
    });

    test('уже прошедший слот не планируем повторно', () {
      // Приложение открыли в 13:00, рассказ ждали в 12:15.
      final plan = planAfter(now: DateTime(2026, 8, 6, 13));

      expect(of(plan, DaySection.story), isNull);
      expect(of(plan, DaySection.course), isNotNull);
    });
  });

  test('утренние и вечерние напоминания ведут в «Мудрость дня»', () {
    final plan = _plan(
      now: _earlyMorning,
      readToday: const {},
      sections: _sections,
    );

    expect(plan.map((r) => r.section).toSet(), {DaySection.wisdom});
  });

  test('идентификаторы новых слотов не пересекаются с прочими', () {
    final plan = _plan(
      now: DateTime(2026, 8, 6, 9, 30),
      readToday: const {},
      sections: _sections,
      wisdomCompletedAt: DateTime(2026, 8, 6, 9, 30),
      storyTitle: 'Память',
    );

    expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
  });

  test('по номеру напоминания понятно, какой это слот', () {
    // Нужен аналитике: из уведомления приходит только его id.
    expect(slotOfReminderId(0), PlannedSlot.morning);
    expect(slotOfReminderId(5), PlannedSlot.morning);
    expect(slotOfReminderId(1), PlannedSlot.evening);
    expect(slotOfReminderId(9), PlannedSlot.afterWisdom);
    expect(slotOfReminderId(10), PlannedSlot.afterWisdom);
    expect(slotOfReminderId(null), PlannedSlot.morning);
  });

  test('дневные напоминания на сегодня видны по плану', () {
    final plan = _plan(
      now: DateTime(2026, 8, 6, 10),
      readToday: const {},
      sections: _sections,
      wisdomCompletedAt: DateTime(2026, 8, 6, 10),
      storyTitle: 'Память',
    );

    final daytime = daytimeRemindersOf(plan, DateTime(2026, 8, 6, 10));
    expect(daytime, (story: true, course: true));
    expect(
      daytimeRemindersOf(
        _plan(now: _earlyMorning, readToday: const {}, sections: _sections),
        _earlyMorning,
      ),
      isNull,
    );
  });
}
