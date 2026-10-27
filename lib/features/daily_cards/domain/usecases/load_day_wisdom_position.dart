import '../../../../core/result/result.dart';
import '../repositories/day_wisdom_position_repository.dart';

class LoadDayWisdomPosition {
  const LoadDayWisdomPosition(this._repository);

  final DayWisdomPositionRepository _repository;

  Result<int?> call(DateTime date) => _repository.load(date);
}
