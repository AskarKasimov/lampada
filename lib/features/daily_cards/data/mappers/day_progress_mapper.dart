import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../dto/day_progress_dto.dart';

extension DayProgressDtoMapper on DayProgressDto {
  /// Бросает [ArgumentError] на неизвестном типе —
  /// repository переводит исключения в Failure.
  DayProgress toEntity() => DayProgress(
        readTypes: readTypes.map(CardType.values.byName).toSet(),
        streakDays: streakDays,
      );
}
