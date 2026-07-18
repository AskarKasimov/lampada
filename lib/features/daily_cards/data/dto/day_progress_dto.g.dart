// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_progress_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DayProgressDto _$DayProgressDtoFromJson(Map<String, dynamic> json) =>
    _DayProgressDto(
      date: json['date'] as String,
      readTypes: (json['readTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      streakDays: (json['streakDays'] as num).toInt(),
      lastCompleted: json['lastCompleted'] as String,
    );

Map<String, dynamic> _$DayProgressDtoToJson(_DayProgressDto instance) =>
    <String, dynamic>{
      'date': instance.date,
      'readTypes': instance.readTypes,
      'streakDays': instance.streakDays,
      'lastCompleted': instance.lastCompleted,
    };
