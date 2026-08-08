import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/record_card_read.dart';

/// Пишет в память и считает вызовы.
class _SpyRepository implements DayProgressRepository {
  final List<String> calls = [];
  Set<CardType> _read = {};
  Set<String> _visited = {};

  DayProgress get _current =>
      DayProgress(readTypes: _read, visitedDays: _visited);

  @override
  Future<Result<DayProgress>> loadToday() async {
    calls.add('loadToday');
    return Success(_current);
  }

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    calls.add('markRead');
    _read = {..._read, type};
    _visited = {..._visited, dateKey(DateTime.now())};
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
}
