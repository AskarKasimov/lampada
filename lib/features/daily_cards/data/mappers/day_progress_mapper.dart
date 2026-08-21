import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../dto/day_progress_dto.dart';

extension DayProgressDtoMapper on DayProgressDto {
  /// Неизвестные типы молча отбрасываются, а не роняют разбор.
  ///
  /// Прогресс — это данные юзера, их нельзя терять из-за того, что мы убрали
  /// тип карточки. Раньше `CardType.values.byName` бросал здесь
  /// `ArgumentError` (это `Error`, не `Exception`, так что и `on Exception`
  /// в репозитории его не ловил): после удаления «вопроса дня» прогресс с
  /// записанным `question` уводил «Сегодня» в офлайн-экран при живом
  /// интернете и загруженных карточках.
  DayProgress toEntity() => DayProgress(
    readTypes: readTypes
        .map((name) => CardType.values.asNameMap()[name])
        .nonNulls
        .toSet(),
    readTypesByDate: {
      for (final entry in readTypesByDate.entries)
        entry.key: entry.value
            .map((name) => CardType.values.asNameMap()[name])
            .nonNulls
            .toSet(),
    },
    visitedDays: visitedDays.toSet(),
  );
}
