import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_reading.freezed.dart';

/// Один стих отрывка — единица показа в ридере: один стих = один экран.
@freezed
abstract class Verse with _$Verse {
  const Verse._();

  const factory Verse({
    /// Номер внутри главы. Показывается подписью, не частью текста.
    required int number,
    required int chapter,
    required String text,

    /// Толкование, относящееся к этому стиху. Открывается из самого стиха,
    /// а не карточкой в конце отрывка: у толкователя мысль привязана к
    /// стиху, и читать её через десять экранов после него бессмысленно.
    String? interpretation,

    /// Отрывок, на который написано толкование («Мф.20:1–7»). У Феофилакта
    /// один блок часто покрывает несколько стихов подряд — тогда текст у них
    /// общий, и подпись честно говорит, на что он написан.
    String? interpretationRange,
  }) = _Verse;

  bool get hasInterpretation =>
      interpretation != null && interpretation!.trim().isNotEmpty;
}

/// Евангельское чтение дня: отрывок постишно, у стихов — святоотеческое
/// толкование (FR-009).
@freezed
abstract class DailyReading with _$DailyReading {
  const DailyReading._();

  const factory DailyReading({
    /// Человекочитаемая ссылка: «Ин.10:1–9».
    required String label,
    required List<Verse> verses,

    /// Один на весь отрывок — страница толкований одна.
    String? interpretationAuthor,
  }) = _DailyReading;

  /// Сколько экранов в ридере. Толкование своей страницы не занимает —
  /// оно открывается со стиха.
  int get pageCount => verses.length;

  bool get hasAnyInterpretation => verses.any((v) => v.hasInterpretation);
}
