import 'package:freezed_annotation/freezed_annotation.dart';

part 'bible_chapter_dto.freezed.dart';
part 'bible_chapter_dto.g.dart';

@freezed
abstract class BibleVerseDto with _$BibleVerseDto {
  const factory BibleVerseDto({required int number, required String text}) =
      _BibleVerseDto;

  factory BibleVerseDto.fromJson(Map<String, dynamic> json) =>
      _$BibleVerseDtoFromJson(json);
}

@freezed
abstract class BibleChapterDto with _$BibleChapterDto {
  const factory BibleChapterDto({
    required String book,
    required int number,
    required List<BibleVerseDto> verses,
  }) = _BibleChapterDto;

  factory BibleChapterDto.fromJson(Map<String, dynamic> json) =>
      _$BibleChapterDtoFromJson(json);
}
