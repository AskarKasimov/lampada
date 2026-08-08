import 'package:freezed_annotation/freezed_annotation.dart';

import 'day_card.dart';

part 'today_cards.freezed.dart';

/// Набор карточек строго за запрошенную дату.
@freezed
abstract class TodayCards with _$TodayCards {
  const factory TodayCards({
    required List<DayCard> cards,

    /// Седмица церковного года: «Седмица 10-я по Пятидесятнице».
    String? week,

    /// Первая память дня: «Мц. Христи́ны Тирской».
    String? title,

    /// Постный ли день.
    @Default(false) bool isFast,
  }) = _TodayCards;

  const TodayCards._();

  /// Есть ли чем назвать день. Азбука публикует память не каждый день, и
  /// шапка без имени должна схлопываться, а не оставлять пустое место.
  ///
  /// Седмица сюда не входит: она свойство недели и живёт над полоской дат,
  /// а не в шапке дня.
  bool get hasName => (title ?? '').isNotEmpty || isFast;
}
