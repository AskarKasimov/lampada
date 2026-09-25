// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_chapter_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BibleVerseDto _$BibleVerseDtoFromJson(Map<String, dynamic> json) =>
    _BibleVerseDto(
      number: (json['number'] as num).toInt(),
      text: json['text'] as String,
    );

Map<String, dynamic> _$BibleVerseDtoToJson(_BibleVerseDto instance) =>
    <String, dynamic>{'number': instance.number, 'text': instance.text};

_BibleChapterDto _$BibleChapterDtoFromJson(Map<String, dynamic> json) =>
    _BibleChapterDto(
      book: json['book'] as String,
      number: (json['number'] as num).toInt(),
      verses: (json['verses'] as List<dynamic>)
          .map((e) => BibleVerseDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BibleChapterDtoToJson(_BibleChapterDto instance) =>
    <String, dynamic>{
      'book': instance.book,
      'number': instance.number,
      'verses': instance.verses,
    };
