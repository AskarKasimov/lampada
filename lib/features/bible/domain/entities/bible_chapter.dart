import 'package:freezed_annotation/freezed_annotation.dart';

part 'bible_chapter.freezed.dart';

@freezed
abstract class BibleVerse with _$BibleVerse {
  const factory BibleVerse({required int number, required String text}) =
      _BibleVerse;
}

@freezed
abstract class BibleChapter with _$BibleChapter {
  const factory BibleChapter({
    required String book,
    required int number,
    required List<BibleVerse> verses,
  }) = _BibleChapter;
}
