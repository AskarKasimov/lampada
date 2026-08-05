import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_card.freezed.dart';

/// Порядок значений enum = фиксированный порядок показа внутри дня:
/// от простого к сложному.
///
enum CardType { quote, advice, basics, reading, question }

/// Единица дневного контента: одна карточка — один экран.
@freezed
abstract class DayCard with _$DayCard {
  const factory DayCard({
    required String id,
    required CardType type,
    required String body,

    /// Источник на Азбуке веры (автор/страница).
    required String source,

    /// Машинная ссылка на отрывок (`Jn.10:1-9`) — только у [CardType.reading],
    /// у остальных null. По ней ридер лениво догружает стихи и толкование:
    /// тянуть их вместе с днём значило бы утроить сетевой путь ради экрана,
    /// до которого доходит меньшинство сессий. В [body] при этом лежит
    /// человекочитаемое «Ин.10:1–9».
    String? reference,
  }) = _DayCard;
}
