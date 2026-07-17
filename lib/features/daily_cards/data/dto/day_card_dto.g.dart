// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_card_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DayCardDto _$DayCardDtoFromJson(Map<String, dynamic> json) => _DayCardDto(
  id: json['id'] as String,
  type: json['type'] as String,
  body: json['body'] as String,
  source: json['source'] as String,
);

Map<String, dynamic> _$DayCardDtoToJson(_DayCardDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'body': instance.body,
      'source': instance.source,
    };
