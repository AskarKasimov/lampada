import 'package:freezed_annotation/freezed_annotation.dart';

part 'bible_chapter.freezed.dart';

@freezed
abstract class BibleVerse with _$BibleVerse {
  const BibleVerse._();

  const factory BibleVerse({
    required int number,
    required String text,

    /// Толкование открывается со стиха, как в чтении дня. Блок на несколько
    /// стихов достаётся последнему из них.
    String? interpretation,

    /// Отрывок, на который написано толкование: «Быт.1:1–2».
    String? interpretationRange,
  }) = _BibleVerse;

  bool get hasInterpretation =>
      interpretation != null && interpretation!.trim().isNotEmpty;
}

@freezed
abstract class BibleChapter with _$BibleChapter {
  const factory BibleChapter({
    required String book,
    required int number,
    required List<BibleVerse> verses,

    /// Один толкователь на главу — страница толкования одна.
    String? interpretationAuthor,
  }) = _BibleChapter;
}
