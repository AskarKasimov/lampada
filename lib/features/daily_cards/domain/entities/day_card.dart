import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_card.freezed.dart';

/// Тип карточки. Порядок значений enum = фиксированный порядок показа
/// внутри дня: от простого к сложному.
enum CardType { quote, question, advice, basics, reading }

/// Одна единица дневного контента. Ровно одна карточка на экран.
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
