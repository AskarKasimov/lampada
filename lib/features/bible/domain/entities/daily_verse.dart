import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_verse.freezed.dart';

/// «Стих дня»: ссылка и текст стиха или короткого отрывка в Синодальном
/// переводе.
@freezed
abstract class DailyVerse with _$DailyVerse {
  const factory DailyVerse({
    /// Код книги из каталога `bibleBooks`.
    required String book,
    required int chapter,

    /// Первый стих.
    required int verse,
    required String text,

    /// Последний стих отрывка; null у одиночного стиха.
    int? endVerse,
  }) = _DailyVerse;

  const DailyVerse._();

  /// «36:5» или «36:5–6».
  String get reference =>
      '$chapter:$verse${endVerse == null ? '' : '–$endVerse'}';
}
