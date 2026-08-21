import '../../../../core/result/result.dart';
import '../entities/daily_reading.dart';
import '../repositories/reading_repository.dart';

/// Чтение дня для ридера. UI вызывает usecase, не репозиторий.
class GetDailyReading {
  const GetDailyReading(this._repository);

  final ReadingRepository _repository;

  Future<Result<DailyReading>> call(
    String reference, {
    bool forceRefresh = false,
  }) => _repository.getReading(reference, forceRefresh: forceRefresh);
}
