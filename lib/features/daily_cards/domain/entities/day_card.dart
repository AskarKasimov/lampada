import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_card.freezed.dart';

/// Порядок значений enum = фиксированный порядок показа внутри дня:
/// от простого к сложному.
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
  }) = _DayCard;
}
