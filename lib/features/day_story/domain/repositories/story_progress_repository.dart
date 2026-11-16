import '../../../../core/result/result.dart';
import '../entities/story_progress.dart';

/// Прочитанные рассказы «Памяти дня»: по дням для напоминаний и по ссылкам
/// для очереди святых дня.
abstract interface class StoryProgressRepository {
  Future<Result<StoryProgress>> load();

  /// Отмечает рассказ [storyUrl] за [date] прочитанным и возвращает
  /// обновлённый прогресс.
  Future<Result<StoryProgress>> markRead(DateTime date, String storyUrl);
}
