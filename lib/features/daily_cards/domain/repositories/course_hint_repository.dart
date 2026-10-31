import '../../../../core/result/result.dart';

/// Одноразовые подсказки читалки курса «Основы веры».
abstract interface class CourseHintRepository {
  /// Показывали ли пульсацию плашки темы, которая открывает оглавление.
  Future<Result<bool>> contentsHintShown();

  Future<Result<void>> markContentsHintShown();
}
