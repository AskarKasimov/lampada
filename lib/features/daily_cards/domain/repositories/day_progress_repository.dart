// lib/features/daily_cards/domain/repositories/day_progress_repository.dart
import '../../../../core/result/result.dart';
import '../entities/day_card.dart';
import '../entities/day_progress.dart';

/// Контракт хранилища прогресса дня. Реализация — в data.
/// Исключения наружу не летят — только Result.
abstract interface class DayProgressRepository {
  /// Прогресс на сегодня. Если сохранённая дата — не сегодня,
  /// список прочитанного пуст (новый день), серия сохраняется.
  Future<Result<DayProgress>> loadToday();

  /// Отметить тип карточки прочитанным сегодня.
  Future<Result<DayProgress>> markRead(CardType type);

  /// Завершить день: серия +1 (не более одного раза в сутки).
  Future<Result<DayProgress>> completeDay();

  /// Сбросить сегодняшний прогресс («Пройти снова») — даёт перечитать
  /// карточки заново. Серию, уже засчитанную за сегодня, не откатывает.
  Future<Result<DayProgress>> resetToday();
}
