import '../../../../core/result/result.dart';

/// Подсказки читалки рассказа «Памяти дня».
abstract interface class StoryHintRepository {
  /// Открывал ли юзер список святых дня плашкой «Память дня». До этого
  /// плашка пульсирует.
  Future<Result<bool>> contentsOpened();

  Future<Result<void>> markContentsOpened();
}
