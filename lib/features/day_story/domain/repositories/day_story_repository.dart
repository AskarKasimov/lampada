import '../../../../core/result/result.dart';
import '../entities/day_story.dart';

abstract interface class DayStoryRepository {
  Future<Result<DayStory>> fetch(String url);
}
