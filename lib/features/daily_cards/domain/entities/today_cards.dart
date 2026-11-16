import 'package:freezed_annotation/freezed_annotation.dart';

import 'day_card.dart';
import 'day_memory.dart';

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

    /// Памяти дня с рассказами, в порядке Азбуки. Плитка показывает первую
    /// непрочитанную; рассказы грузятся лениво, а не вместе с днём.
    @Default(<DayMemory>[]) List<DayMemory> memories,

    /// Адрес «Картины дня» Азбуки: иллюстрация плитки «Мудрость дня».
    String? pictureUrl,
  }) = _TodayCards;

  const TodayCards._();

  /// Есть ли чем назвать день. Азбука публикует память не каждый день, и
  /// шапка без имени должна схлопываться, а не оставлять пустое место.
  ///
  /// Седмица сюда не входит: это свойство недели, а не имя дня.
  bool get hasName => (title ?? '').isNotEmpty || isFast;
}
