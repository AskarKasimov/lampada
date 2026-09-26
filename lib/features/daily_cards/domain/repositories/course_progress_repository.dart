import '../../../../core/result/result.dart';

/// Место чтения и явно завершённые темы личного курса «Основы веры».
abstract interface class CourseProgressRepository {
  /// Номер темы, на которой юзер остановился. Новый юзер — тема 1.
  Future<Result<int>> currentTopic();

  /// Сохраняет последнюю открытую тему курса.
  Future<Result<void>> saveCurrentTopic(int topic);

  Future<Result<Set<int>>> completedTopics();

  /// Повторная отметка не увеличивает прогресс и не меняет место чтения.
  Future<Result<void>> completeTopic(int topic);
}
