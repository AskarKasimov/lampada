import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_progress_dto.freezed.dart';
part 'day_progress_dto.g.dart';

/// Сериализуемое состояние прогресса в хранилище. Не покидает data-слой —
/// наружу только entity через mapper.
@freezed
abstract class DayProgressDto with _$DayProgressDto {
  const factory DayProgressDto({
    /// Дата (yyyy-MM-dd), к которой относится [readTypes].
    required String date,

    /// Имена прочитанных сегодня типов (CardType.name).
    required List<String> readTypes,

    /// Даты (yyyy-MM-dd) с активностью. Серия выводится из них, а не хранится
    /// числом: счётчик было негде сбрасывать, и он только рос.
    @Default(<String>[]) List<String> visitedDays,
  }) = _DayProgressDto;

  factory DayProgressDto.fromJson(Map<String, dynamic> json) =>
      _$DayProgressDtoFromJson(json);
}
