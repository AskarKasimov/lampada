import '../../../../core/result/result.dart';
import '../repositories/day_wisdom_position_repository.dart';

class SaveDayWisdomPosition {
  const SaveDayWisdomPosition(this._repository);

  final DayWisdomPositionRepository _repository;

  Future<Result<void>> call(DateTime date, int pageIndex) =>
      _repository.save(date, pageIndex);
}
