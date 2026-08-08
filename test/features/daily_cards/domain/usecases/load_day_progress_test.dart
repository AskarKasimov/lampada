import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/load_day_progress.dart';

class _DayProgressRepository implements DayProgressRepository {
  _DayProgressRepository(this.result);

  final Result<DayProgress> result;
  var loadCalls = 0;

  @override
  Future<Result<DayProgress>> loadToday() async {
    loadCalls++;
    return result;
  }

  @override
  Future<Result<DayProgress>> markRead(CardType type) async =>
      const Success(DayProgress(readTypes: {}, visitedDays: {}));
}

void main() {
  test('загружает прогресс через репозиторий', () async {
    const progress = DayProgress(readTypes: {CardType.quote}, visitedDays: {});
    final repository = _DayProgressRepository(const Success(progress));

    final result = await LoadDayProgress(repository)();

    expect(result, same(repository.result));
    expect(repository.loadCalls, 1);
  });

  test('сохраняет ошибку загрузки прогресса', () async {
    const failure = AppFailure('Ошибка', kind: FailureKind.unknown);
    final repository = _DayProgressRepository(const Failure(failure));

    final result = await LoadDayProgress(repository)();

    expect(result, same(repository.result));
    expect(repository.loadCalls, 1);
  });
}
