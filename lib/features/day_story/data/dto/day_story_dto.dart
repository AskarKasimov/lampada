import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_story_dto.freezed.dart';
part 'day_story_dto.g.dart';

/// DTO рассказа о дне. Не выходит за пределы data-слоя; наружу — entity
/// через mapper. JSON нужен для кэша по ссылке в prefs.
@freezed
abstract class DayStoryDto with _$DayStoryDto {
  const factory DayStoryDto({required List<String> paragraphs}) = _DayStoryDto;

  factory DayStoryDto.fromJson(Map<String, dynamic> json) =>
      _$DayStoryDtoFromJson(json);
}
