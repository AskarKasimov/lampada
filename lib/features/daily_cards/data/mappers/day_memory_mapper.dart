import '../../domain/entities/day_memory.dart';
import '../dto/day_memory_dto.dart';

extension DayMemoryDtoMapper on DayMemoryDto {
  DayMemory toEntity() => DayMemory(title: title, storyUrl: storyUrl);
}
