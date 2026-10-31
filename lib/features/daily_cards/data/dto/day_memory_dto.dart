import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_memory_dto.freezed.dart';
part 'day_memory_dto.g.dart';

/// Одна память из списка дня на Азбуке: святой, праздник или икона со
/// своей страницей, где лежит рассказ и икона.
@freezed
abstract class DayMemoryDto with _$DayMemoryDto {
  const factory DayMemoryDto({
    /// «Прп. Фомы́, иже в Мале́и», без годов жизни.
    required String title,

    /// Страница памяти на azbyka.ru, всегда по HTTPS.
    required String storyUrl,
  }) = _DayMemoryDto;

  factory DayMemoryDto.fromJson(Map<String, dynamic> json) =>
      _$DayMemoryDtoFromJson(json);
}
