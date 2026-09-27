import '../../../../core/result/result.dart';

/// Место чтения и явно завершённые темы личного курса «Основы веры».
abstract interface class CourseProgressRepository {
  /// Начат ли курс явно; чтение каталога само по себе его не активирует.
  Future<Result<bool>> hasStarted();

  /// Номер темы, на которой юзер остановился. Новый юзер — тема 1.
  Future<Result<int>> currentTopic();

  /// Сохраняет последнюю открытую тему курса.
  Future<Result<void>> saveCurrentTopic(int topic, {int page = 0});

  /// Индекс карточки внутри темы; null у старого прогресса без страницы.
  Future<Result<int?>> currentPage(int topic);

  Future<Result<Set<int>>> completedTopics();

  /// Повторная отметка не увеличивает прогресс и не меняет место чтения.
  Future<Result<void>> completeTopic(int topic);
}
