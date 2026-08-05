// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookmarkDto _$BookmarkDtoFromJson(Map<String, dynamic> json) => _BookmarkDto(
  id: json['id'] as String,
  kind: json['kind'] as String,
  text: json['text'] as String,
  source: json['source'] as String,
  label: json['label'] as String,
  savedAt: json['savedAt'] as String,
);

Map<String, dynamic> _$BookmarkDtoToJson(_BookmarkDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'text': instance.text,
      'source': instance.source,
      'label': instance.label,
      'savedAt': instance.savedAt,
    };
