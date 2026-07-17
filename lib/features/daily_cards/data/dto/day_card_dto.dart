import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_card_dto.freezed.dart';
part 'day_card_dto.g.dart';

/// DTO внешнего источника (Азбука веры). Не выходит за пределы data-слоя —
/// наружу только entity через mapper.
@freezed
abstract class DayCardDto with _$DayCardDto {
  const factory DayCardDto({
    required String id,
    /// Строковый тип из источника: quote | advice | basics | reading.
    required String type,
    required String body,
    required String source,
  }) = _DayCardDto;

  factory DayCardDto.fromJson(Map<String, dynamic> json) =>
      _$DayCardDtoFromJson(json);
}
