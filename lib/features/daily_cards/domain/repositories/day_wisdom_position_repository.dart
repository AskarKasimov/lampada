import '../../../../core/result/result.dart';

/// Хранит последнюю страницу «Мудрости дня» для сегодняшней даты.
abstract interface class DayWisdomPositionRepository {
  Result<int?> load(DateTime date);

  Future<Result<void>> save(DateTime date, int pageIndex);
}
