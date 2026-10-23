import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_verse.freezed.dart';

/// «Стих дня»: ссылка и текст стиха в Синодальном переводе.
@freezed
abstract class DailyVerse with _$DailyVerse {
  const factory DailyVerse({
    /// Код книги из каталога `bibleBooks`.
    required String book,
    required int chapter,
    required int verse,
    required String text,
  }) = _DailyVerse;
}
