import '../../../../core/result/result.dart';
import '../entities/day_progress.dart';
import '../repositories/day_progress_repository.dart';

/// Отмечает «Мудрость дня» дочитанной до экрана итога.
///
/// Чтение отдельных карточек серию не продлевает: день засчитывается
/// ([markVisited]), только когда юзер дошёл до экрана итога.
class CompleteDayWisdom {
  const CompleteDayWisdom(this._repository);

  final DayProgressRepository _repository;

  Future<Result<DayProgress>> call({DateTime? date, bool markVisited = true}) =>
      _repository.completeWisdom(date: date, markVisited: markVisited);
}
