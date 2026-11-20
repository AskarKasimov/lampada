import '../../../../core/result/result.dart';
import '../entities/day_progress.dart';
import '../repositories/streak_hint_repository.dart';

/// Решает, объяснить ли на итоге раздела, что вчерашний пропуск не погасил
/// лампаду, а заморозил её на день.
///
/// Объясняем только первую заморозку: дальше значок замороженного дня в
/// неделе говорит сам за себя. Отметка ставится сразу, как только решили
/// показать: итог разыгрывается один раз за день, и повторять фразу при
/// следующем пропуске незачем.
class ExplainStreakFreeze {
  ExplainStreakFreeze(this._hints);

  final StreakHintRepository _hints;

  /// [before] — прогресс до сегодняшнего зажжения.
  Future<bool> call({
    required DayProgress before,
    required DateTime today,
  }) async {
    if (!before.isFrozenOn(today)) return false;
    // Не смогли прочитать отметку: лучше промолчать, чем повторять фразу.
    if (await _hints.freezeExplained() case Success(value: false)) {
      await _hints.markFreezeExplained();
      return true;
    }
    return false;
  }
}
