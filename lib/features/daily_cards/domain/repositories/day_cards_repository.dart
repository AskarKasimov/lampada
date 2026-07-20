import '../../../../core/result/result.dart';
import '../entities/today_cards.dart';

/// Контракт domain-слоя. Реализация живёт в data.
/// Исключения наружу не летят — только Result.
abstract interface class DayCardsRepository {
  Future<Result<TodayCards>> getCardsFor(DateTime date);
}
