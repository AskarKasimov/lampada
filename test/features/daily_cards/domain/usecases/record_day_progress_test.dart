import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/complete_day_wisdom.dart';
import 'package:lampada/features/daily_cards/domain/usecases/record_card_read.dart';

/// Пишет в память и считает вызовы.
class _SpyRepository implements DayProgressRepository {
  final List<String> calls = [];
  Set<CardType> _read = {};
  Set<String> _visited = {};
  Set<String> _completed = {};

  DayProgress get _current => DayProgress(
    readTypes: _read,
    visitedDays: _visited,
    wisdomCompletedDays: _completed,
  );

  @override
  Future<Result<DayProgress>> loadToday() async {
    calls.add('loadToday');
    return Success(_current);
  }

  @override
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) async {
    calls.add('markRead');
    _read = {..._read, type};
    if (markVisited) _visited = {..._visited, dateKey(date ?? DateTime.now())};
    return Success(_current);
  }

  @override
  Future<Result<DayProgress>> completeWisdom({
    DateTime? date,
    bool markVisited = true,
  }) async {
    calls.add('completeWisdom');
    final day = dateKey(date ?? DateTime.now());
    _completed = {..._completed, day};
    if (markVisited) _visited = {..._visited, day};
    return Success(_current);
  }
}

void main() {
  group('RecordCardRead', () {
    test('карточка засчитывается', () async {
      final repo = _SpyRepository();

      final result = await RecordCardRead(repo)(CardType.quote);

      expect(repo.calls, ['markRead']);
      expect(
        (result as Success<DayProgress>).value.readTypes,
        contains(CardType.quote),
      );
    });

    test('зажигает сегодняшний день', () async {
      // «Лампадка» отмечает дни с активностью, и первая же карточка
      // делает день состоявшимся (§1).
      final repo = _SpyRepository();

      final result = await RecordCardRead(repo)(CardType.quote);

      expect(
        (result as Success<DayProgress>).value.isLit(DateTime.now()),
        isTrue,
      );
    });
  });

  group('CompleteDayWisdom', () {
    test('отмечает завершение и зажигает день без отметки карточек', () async {
      final repo = _SpyRepository();
      final today = DateTime.now();

      final result = await CompleteDayWisdom(repo)(date: today);

      expect(repo.calls, ['completeWisdom']);
      final progress = (result as Success<DayProgress>).value;
      expect(progress.isWisdomCompletedOn(today), isTrue);
      expect(progress.isLit(today), isTrue);
      expect(progress.readTypes, isEmpty);
    });

    test('без засчитывания дня серию не трогает', () async {
      final repo = _SpyRepository();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final result = await CompleteDayWisdom(repo)(
        date: yesterday,
        markVisited: false,
      );

      final progress = (result as Success<DayProgress>).value;
      expect(progress.isWisdomCompletedOn(yesterday), isTrue);
      expect(progress.isLit(yesterday), isFalse);
    });
  });
}
