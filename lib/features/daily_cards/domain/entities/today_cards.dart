import 'package:freezed_annotation/freezed_annotation.dart';

import 'day_card.dart';

part 'today_cards.freezed.dart';

/// Набор карточек строго за запрошенную дату.
@freezed
abstract class TodayCards with _$TodayCards {
  const factory TodayCards({required List<DayCard> cards}) = _TodayCards;
}
