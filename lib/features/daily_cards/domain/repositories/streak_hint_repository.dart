import '../../../../core/result/result.dart';

/// Подсказки карточки серии «Лампадки».
abstract interface class StreakHintRepository {
  /// Объясняли ли юзеру, что после пропуска лампада была заморожена.
  Future<Result<bool>> freezeExplained();

  Future<Result<void>> markFreezeExplained();
}
