import '../../../../core/result/result.dart';
import '../entities/day_story.dart';
import '../repositories/day_story_repository.dart';

/// Рассказ о дне для экрана-читалки. UI вызывает usecase, не репозиторий.
class GetDayStory {
  const GetDayStory(this._repository);

  final DayStoryRepository _repository;

  Future<Result<DayStory>> call(String url) => _repository.fetch(url);
}
