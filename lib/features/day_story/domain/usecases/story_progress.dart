import '../../../../core/result/result.dart';
import '../entities/story_progress.dart';
import '../repositories/story_progress_repository.dart';

/// Прочитанные рассказы «Памяти дня».
class LoadStoryProgress {
  const LoadStoryProgress(this._repository);

  final StoryProgressRepository _repository;

  Future<Result<StoryProgress>> call() => _repository.load();
}

/// Показ последней страницы рассказа считается прочтением этого святого.
class MarkStoryRead {
  const MarkStoryRead(this._repository);

  final StoryProgressRepository _repository;

  Future<Result<StoryProgress>> call(DateTime date, String storyUrl) =>
      _repository.markRead(date, storyUrl);
}
