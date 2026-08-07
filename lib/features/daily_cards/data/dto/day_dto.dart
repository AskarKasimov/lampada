import 'package:freezed_annotation/freezed_annotation.dart';

import 'day_card_dto.dart';

part 'day_dto.freezed.dart';
part 'day_dto.g.dart';

/// Страница дня целиком: карточки и то, как этот день зовётся в календаре.
///
/// Карточки и имя приходят с одной и той же страницы Азбуки, поэтому едут
/// вместе — иначе за подписью «Седмица 10-я по Пятидесятнице» пришлось бы
/// ходить вторым запросом за тем же самым HTML.
@freezed
abstract class DayDto with _$DayDto {
  const factory DayDto({
    required List<DayCardDto> cards,

    /// «Седмица 10-я по Пятидесятнице».
    String? week,

    /// Первая память дня: «Мц. Христи́ны Тирской (ок. 300)».
    String? title,

    /// Постный ли день. По умолчанию false: отсутствие пометки на странице
    /// значит именно «не постный», а не «неизвестно».
    @Default(false) bool isFast,
  }) = _DayDto;

  factory DayDto.fromJson(Map<String, dynamic> json) => _$DayDtoFromJson(json);
}
