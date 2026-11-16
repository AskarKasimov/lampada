import '../../../../core/result/result.dart';

/// Подсказки читалки курса «Основы веры».
abstract interface class CourseHintRepository {
  /// Открывал ли юзер оглавление плашкой темы. До этого плашка пульсирует.
  Future<Result<bool>> contentsOpened();

  Future<Result<void>> markContentsOpened();
}
