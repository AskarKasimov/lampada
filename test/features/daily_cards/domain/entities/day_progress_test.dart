import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';

final _today = DateTime(2026, 7, 28);

/// Дни активности заданием «сколько суток назад» — так условие теста читается
/// как сценарий, а не как список дат.
DayProgress _progressDaysAgo(List<int> daysAgo) => DayProgress(
  readTypes: const {},
  visitedDays: daysAgo
      .map((d) => dateKey(_today.subtract(Duration(days: d))))
      .toSet(),
);

void main() {
  group('серия «Лампадки»', () {
    test('без активности огонька нет', () {
      expect(_progressDaysAgo([]).streakOn(_today), 0);
    });

    test('только сегодня — один день', () {
      expect(_progressDaysAgo([0]).streakOn(_today), 1);
    });

    test('подряд идущие дни складываются', () {
      expect(_progressDaysAgo([0, 1, 2, 3]).streakOn(_today), 4);
    });

    // FR-020 / SC-008: буфер в один пропущенный день.
    test('один пропущенный день серию НЕ гасит', () {
      // Заходил сегодня и позавчера, вчера пропустил.
      expect(_progressDaysAgo([0, 2]).streakOn(_today), 2);
    });

    test('два пропуска подряд серию рвут', () {
      // Заходил сегодня и четыре дня назад — между ними три пустых дня.
      expect(_progressDaysAgo([0, 3]).streakOn(_today), 1);
    });

    test('разрыв обрезает только хвост, начало серии остаётся', () {
      // 0,1,2 подряд; затем провал; 6 и 7 в серию уже не входят.
      expect(_progressDaysAgo([0, 1, 2, 6, 7]).streakOn(_today), 3);
    });

    test('вчерашний заход держит огонёк', () {
      expect(_progressDaysAgo([1]).streakOn(_today), 1);
    });

    test('позавчерашний заход держит огонёк — это ещё буфер', () {
      expect(_progressDaysAgo([2]).streakOn(_today), 1);
    });

    test('три дня без захода — огонёк притух', () {
      expect(_progressDaysAgo([3]).streakOn(_today), 0);
    });

    test('после месяца отсутствия серия не продолжается с прежнего числа', () {
      // Ровно тот баг, который был: счётчик только рос и никогда не сбрасывался.
      final long = _progressDaysAgo([30, 31, 32, 33, 34]);

      expect(long.streakOn(_today), 0);
    });

    test('будущие даты в серию не берутся', () {
      // Переставленные часы или смена таймзоны не должны надувать серию.
      final withFuture = DayProgress(
        readTypes: const {},
        visitedDays: {
          dateKey(_today),
          dateKey(_today.add(const Duration(days: 5))),
        },
      );

      expect(withFuture.streakOn(_today), 1);
    });

    test('переход на летнее время не сбивает счёт суток', () {
      // Внутри интервала 25-часовые сутки: inDays по локальному времени
      // округлился бы вниз и разорвал непрерывную серию.
      final dst = DateTime(2026, 3, 30);
      final progress = DayProgress(
        readTypes: const {},
        visitedDays: {
          for (var i = 0; i < 4; i++) dateKey(dst.subtract(Duration(days: i))),
        },
      );

      expect(progress.streakOn(dst), 4);
    });
  });

  group('огонёк дня', () {
    test('isLit отмечает только дни с активностью', () {
      final progress = _progressDaysAgo([0, 2]);

      expect(progress.isLit(_today), isTrue);
      expect(progress.isLit(_today.subtract(const Duration(days: 1))), isFalse);
      expect(progress.isLit(_today.subtract(const Duration(days: 2))), isTrue);
    });
  });

  group('прочитанность дня', () {
    test('allReadOf считает от карточек этого дня, а не от всех типов', () {
      // Неполный день (Азбука отдала не все секции) обязан закрываться.
      const progress = DayProgress(
        readTypes: {CardType.quote, CardType.advice},
        visitedDays: {},
      );

      expect(progress.allReadOf([CardType.quote, CardType.advice]), isTrue);
      expect(progress.allReadOf(CardType.values), isFalse);
    });

    test('день без карточек прочитанным не считается', () {
      const progress = DayProgress(readTypes: {}, visitedDays: {});

      expect(progress.allReadOf(const []), isFalse);
    });

    test('firstUnreadOf уважает переданный порядок', () {
      const progress = DayProgress(
        readTypes: {CardType.quote},
        visitedDays: {},
      );

      expect(
        progress.firstUnreadOf([CardType.quote, CardType.basics]),
        CardType.basics,
      );
    });
  });
}
