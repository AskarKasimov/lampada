import '../../../../core/result/result.dart';
import '../entities/day_card.dart';
import '../entities/day_progress.dart';

/// Контракт хранилища прогресса дня. Реализация — в data.
/// Исключения наружу не летят — только Result.
abstract interface class DayProgressRepository {
  /// Прогресс на сегодня вместе с историей прочитанного по датам.
  Future<Result<DayProgress>> loadToday();

  /// Отмечает тип прочитанным для [date].
  ///
  /// Только [markVisited] зажигает «Лампадку» даты: перечитывание старого
  /// контента сохраняется, но не меняет историю посещений.
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  });

  /// Отмечает, что «Мудрость дня» за [date] дочитана до экрана итога.
  ///
  /// [markVisited] зажигает «Лампадку» даты, не отмечая прочитанной ни одну
  /// карточку: только так чтение «Мудрости дня» продлевает серию.
  Future<Result<DayProgress>> completeWisdom({
    DateTime? date,
    bool markVisited = true,
  });
}
