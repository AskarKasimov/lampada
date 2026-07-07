import '../../../../core/result/result.dart';
import '../entities/day_card.dart';

/// Контракт domain-слоя. Реализация живёт в data.
/// Исключения наружу не летят — только Result.
abstract interface class DayCardsRepository {
  Future<Result<List<DayCard>>> getCardsFor(DateTime date);
}
