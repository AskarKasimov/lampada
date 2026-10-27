import 'package:freezed_annotation/freezed_annotation.dart';

part 'bible_reading_position.freezed.dart';

@freezed
abstract class BibleReadingPosition with _$BibleReadingPosition {
  const factory BibleReadingPosition({
    required String book,
    required int chapter,
    required int verse,
  }) = _BibleReadingPosition;
}
