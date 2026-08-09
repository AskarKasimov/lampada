import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_card_dto.freezed.dart';
part 'day_card_dto.g.dart';

/// DTO внешнего источника (Азбука веры). Не выходит за пределы data-слоя —
/// наружу только entity через mapper.
@freezed
abstract class DayCardDto with _$DayCardDto {
  const factory DayCardDto({
    required String id,

    /// Строковый тип из источника: quote | advice | basics | reading | parable.
    required String type,
    required String body,
    required String source,

    /// Ссылка на отрывок (`Jn.10:1-9`) — только у карточки чтения.
    String? reference,

    /// Название темы — только у «Основ»: «Свойство Божье – всесовершенство».
    /// У остальных типов заголовка нет, там сам текст и есть содержание.
    String? title,
  }) = _DayCardDto;

  factory DayCardDto.fromJson(Map<String, dynamic> json) =>
      _$DayCardDtoFromJson(json);
}
