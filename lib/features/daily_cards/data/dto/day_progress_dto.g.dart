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
      readTypesByDate:
          (json['readTypesByDate'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          const <String, List<String>>{},
      visitedDays:
          (json['visitedDays'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$DayProgressDtoToJson(_DayProgressDto instance) =>
    <String, dynamic>{
      'date': instance.date,
      'readTypes': instance.readTypes,
      'readTypesByDate': instance.readTypesByDate,
      'visitedDays': instance.visitedDays,
    };
