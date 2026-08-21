import '../../../../core/result/result.dart';
import '../entities/daily_reading.dart';

abstract interface class ReadingRepository {
  /// [reference] — машинная ссылка отрывка вида `Jn.10:1-9`,
  /// её отдаёт карточка чтения дня.
  Future<Result<DailyReading>> getReading(
    String reference, {
    bool forceRefresh = false,
  });
}
