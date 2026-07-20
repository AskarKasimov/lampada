import '../../../../core/result/result.dart';
import '../entities/day_card.dart';
import '../entities/day_progress.dart';
import '../entities/today_cards.dart';
import '../repositories/day_progress_repository.dart';

/// Отмечает карточку прочитанной — но только если сессия идёт по контенту
/// запрошенного дня: прогресс должен отражать сегодняшний контент, а не факт
/// свайпов. Когда сеть недоступна и показан кэш за другую дату, сегодняшних
/// карточек юзер не видел — засчитывать их было бы подлогом, а завтра он
/// увидел бы закрашенные чипсы за день, который не читал. См. [CompleteDay] —
/// там то же правило для серии.
class RecordCardRead {
  const RecordCardRead(this._repository);

  final DayProgressRepository _repository;

  Future<Result<DayProgress>> call(
    CardType type, {
    required TodayCards session,
  }) {
    if (session.staleDate != null) return _repository.loadToday();
    return _repository.markRead(type);
  }
}
