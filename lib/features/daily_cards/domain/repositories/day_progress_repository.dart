import '../../../../core/result/result.dart';
import '../entities/day_card.dart';
import '../entities/day_progress.dart';

/// Контракт хранилища прогресса дня. Реализация — в data.
/// Исключения наружу не летят — только Result.
abstract interface class DayProgressRepository {
  /// Прогресс на сегодня. Если сохранённая дата — не сегодня,
  /// список прочитанного пуст (новый день), посещённые дни сохраняются.
  Future<Result<DayProgress>> loadToday();

  /// Отмечает тип прочитанным и заодно засчитывает сегодняшний день
  /// посещённым: по §1 сессия состоялась уже после первой карточки, так что
  /// отдельного «завершить день» не требуется.
  Future<Result<DayProgress>> markRead(CardType type);
}
