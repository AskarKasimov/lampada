// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_reading_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerseDto _$VerseDtoFromJson(Map<String, dynamic> json) => _VerseDto(
  number: (json['number'] as num).toInt(),
  chapter: (json['chapter'] as num).toInt(),
  text: json['text'] as String,
  interpretation: json['interpretation'] as String?,
  interpretationRange: json['interpretationRange'] as String?,
);

Map<String, dynamic> _$VerseDtoToJson(_VerseDto instance) => <String, dynamic>{
  'number': instance.number,
  'chapter': instance.chapter,
  'text': instance.text,
  'interpretation': instance.interpretation,
  'interpretationRange': instance.interpretationRange,
};

_DailyReadingDto _$DailyReadingDtoFromJson(Map<String, dynamic> json) =>
    _DailyReadingDto(
      label: json['label'] as String,
      verses: (json['verses'] as List<dynamic>)
          .map((e) => VerseDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      interpretationAuthor: json['interpretationAuthor'] as String?,
    );

Map<String, dynamic> _$DailyReadingDtoToJson(_DailyReadingDto instance) =>
    <String, dynamic>{
      'label': instance.label,
      'verses': instance.verses,
      'interpretationAuthor': instance.interpretationAuthor,
    };
