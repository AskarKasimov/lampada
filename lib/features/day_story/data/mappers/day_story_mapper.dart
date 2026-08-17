import '../../domain/entities/day_story.dart';
import '../dto/day_story_dto.dart';

extension DayStoryDtoMapper on DayStoryDto {
  DayStory toEntity() => DayStory(paragraphs: paragraphs);
}
