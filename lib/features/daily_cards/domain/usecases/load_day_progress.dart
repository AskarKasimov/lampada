import '../../../../core/result/result.dart';
import '../entities/day_progress.dart';
import '../repositories/day_progress_repository.dart';

class LoadDayProgress {
  const LoadDayProgress(this._repository);

  final DayProgressRepository _repository;

  Future<Result<DayProgress>> call() => _repository.loadToday();
}
