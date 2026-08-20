// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_story_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DayStoryDto _$DayStoryDtoFromJson(Map<String, dynamic> json) => _DayStoryDto(
  paragraphs: (json['paragraphs'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$DayStoryDtoToJson(_DayStoryDto instance) =>
    <String, dynamic>{'paragraphs': instance.paragraphs};
