import '../../../../core/result/result.dart';
import '../entities/day_card.dart';
import '../entities/day_progress.dart';
import '../repositories/day_progress_repository.dart';

/// Отмечает карточку прочитанной в дате, к которой относится контент.
class RecordCardRead {
  const RecordCardRead(this._repository);

  final DayProgressRepository _repository;

  Future<Result<DayProgress>> call(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) => _repository.markRead(type, date: date, markVisited: markVisited);
}
