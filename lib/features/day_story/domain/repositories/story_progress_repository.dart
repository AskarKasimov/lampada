import '../../../../core/result/result.dart';

/// Дни (yyyy-MM-dd), в которые открывали рассказ «Памяти дня». Нужны, чтобы
/// не напоминать о святом тому, кто уже прочитал.
abstract interface class StoryProgressRepository {
  Future<Result<Set<String>>> readDays();

  /// Отмечает рассказ за [date] прочитанным и возвращает обновлённый набор.
  Future<Result<Set<String>>> markRead(DateTime date);
}
