import 'package:freezed_annotation/freezed_annotation.dart';

import 'day_card.dart';

part 'today_cards.freezed.dart';

/// Набор карточек дня вместе с признаком свежести.
///
/// [staleDate] равен null, когда карточки относятся к запрошенному дню. Если
/// не null — это последний закэшированный набор за другую дату, показанный
/// вместо недоступной сети. UI обязан пометить такой набор, иначе юзер примет
/// вчерашний контент за сегодняшний.
@freezed
abstract class TodayCards with _$TodayCards {
  const factory TodayCards({
    required List<DayCard> cards,
    DateTime? staleDate,
  }) = _TodayCards;
}
