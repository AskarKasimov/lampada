import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_reading_dto.freezed.dart';
part 'daily_reading_dto.g.dart';

@freezed
abstract class VerseDto with _$VerseDto {
  const factory VerseDto({
    required int number,
    required int chapter,
    required String text,
    String? interpretation,
    String? interpretationRange,
  }) = _VerseDto;

  factory VerseDto.fromJson(Map<String, dynamic> json) =>
      _$VerseDtoFromJson(json);
}

/// DTO чтения дня. Не выходит за пределы data-слоя; наружу — entity
/// через mapper. JSON нужен для кэша отрывка в prefs.
@freezed
abstract class DailyReadingDto with _$DailyReadingDto {
  const factory DailyReadingDto({
    required String label,
    required List<VerseDto> verses,
    String? interpretationAuthor,
  }) = _DailyReadingDto;

  factory DailyReadingDto.fromJson(Map<String, dynamic> json) =>
      _$DailyReadingDtoFromJson(json);
}
