import '../../../../core/result/result.dart';
import '../entities/day_progress.dart';
import '../entities/today_cards.dart';
import '../repositories/day_progress_repository.dart';

/// Закрывает день и наращивает серию — но только если сессия шла по контенту
/// запрошенного дня.
///
/// На карточках за другую дату день не засчитывается: сегодняшнего контента
/// юзер не видел, значит огонёк на сегодня не зажжён. Возвращает при этом
/// актуальный прогресс, а не пустой, — экрану завершения есть что показать.
/// Парное правило для отдельных карточек — в [RecordCardRead].
class CompleteDay {
  const CompleteDay(this._repository);

  final DayProgressRepository _repository;

  Future<Result<DayProgress>> call({required TodayCards session}) {
    if (session.staleDate != null) return _repository.loadToday();
    return _repository.completeDay();
  }
}
