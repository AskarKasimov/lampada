import 'package:freezed_annotation/freezed_annotation.dart';

import 'day_card.dart';

part 'today_cards.freezed.dart';

/// Набор карточек дня с признаком свежести.
///
/// [staleDate] — null для карточек нужного дня; иначе это последний
/// закэшированный набор за другую дату (сеть недоступна). UI обязан
/// пометить его, иначе юзер примет вчерашний контент за сегодняшний.
@freezed
abstract class TodayCards with _$TodayCards {
  const factory TodayCards({
    required List<DayCard> cards,
    DateTime? staleDate,
  }) = _TodayCards;
}
