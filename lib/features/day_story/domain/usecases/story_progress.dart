import '../../../../core/result/result.dart';
import '../repositories/story_progress_repository.dart';

/// Дни, в которые рассказ «Памяти дня» уже открывали.
class LoadReadStoryDays {
  const LoadReadStoryDays(this._repository);

  final StoryProgressRepository _repository;

  Future<Result<Set<String>>> call() => _repository.readDays();
}

/// Открытие рассказа считается прочтением: напоминание зовёт открыть его.
class MarkStoryRead {
  const MarkStoryRead(this._repository);

  final StoryProgressRepository _repository;

  Future<Result<Set<String>>> call(DateTime date) => _repository.markRead(date);
}
