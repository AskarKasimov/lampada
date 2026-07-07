import '../../domain/entities/day_card.dart';
import '../dto/day_card_dto.dart';

extension DayCardDtoMapper on DayCardDto {
  /// Бросает [ArgumentError] на неизвестном типе —
  /// repository impl переводит исключения в Failure.
  DayCard toEntity() => DayCard(
        id: id,
        type: CardType.values.byName(type),
        title: title,
        body: body,
        source: source,
      );
}
