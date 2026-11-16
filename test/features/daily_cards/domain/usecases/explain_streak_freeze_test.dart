import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/streak_hint_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/explain_streak_freeze.dart';

class _MemoryHints implements StreakHintRepository {
  _MemoryHints({this.fails = false});

  var explained = false;
  final bool fails;
  var marks = 0;

  static const _failure = AppFailure('Нет доступа', kind: FailureKind.unknown);

  @override
  Future<Result<bool>> freezeExplained() async =>
      fails ? const Failure(_failure) : Success(explained);

  @override
  Future<Result<void>> markFreezeExplained() async {
    marks++;
    explained = true;
    return const Success(null);
  }
}

final _today = DateTime(2026, 11, 16);

DayProgress _visitedDaysAgo(List<int> daysAgo) => DayProgress(
  readTypes: const {},
  visitedDays: {
    for (final d in daysAgo) dateKey(_today.subtract(Duration(days: d))),
  },
);

void main() {
  test('первая заморозка объясняется, и это запоминается', () async {
    final hints = _MemoryHints();
    final explain = ExplainStreakFreeze(hints);

    final first = await explain(before: _visitedDaysAgo([2]), today: _today);
    final second = await explain(before: _visitedDaysAgo([2]), today: _today);

    expect(first, isTrue);
    expect(second, isFalse);
    expect(hints.marks, 1);
  });

  test('без заморозки объяснять нечего, отметка не ставится', () async {
    final hints = _MemoryHints();

    final shown = await ExplainStreakFreeze(hints)(
      before: _visitedDaysAgo([1]),
      today: _today,
    );

    expect(shown, isFalse);
    expect(hints.marks, 0);
  });

  test('если прочитать отметку не удалось, объяснение не показываем', () async {
    final hints = _MemoryHints(fails: true);

    final shown = await ExplainStreakFreeze(hints)(
      before: _visitedDaysAgo([2]),
      today: _today,
    );

    expect(shown, isFalse);
    expect(hints.marks, 0);
  });
}
