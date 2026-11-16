// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DayDto _$DayDtoFromJson(Map<String, dynamic> json) => _DayDto(
  cards: (json['cards'] as List<dynamic>)
      .map((e) => DayCardDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  week: json['week'] as String?,
  title: json['title'] as String?,
  isFast: json['isFast'] as bool? ?? false,
  memories:
      (json['memories'] as List<dynamic>?)
          ?.map((e) => DayMemoryDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DayMemoryDto>[],
  pictureUrl: json['pictureUrl'] as String?,
);

Map<String, dynamic> _$DayDtoToJson(_DayDto instance) => <String, dynamic>{
  'cards': instance.cards,
  'week': instance.week,
  'title': instance.title,
  'isFast': instance.isFast,
  'memories': instance.memories,
  'pictureUrl': instance.pictureUrl,
};
