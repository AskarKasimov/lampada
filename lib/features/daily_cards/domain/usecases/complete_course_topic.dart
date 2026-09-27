import '../../../../core/result/result.dart';
import '../course_calendar.dart';
import '../entities/day_card.dart';
import '../entities/day_progress.dart';
import '../repositories/course_progress_repository.dart';
import '../repositories/day_progress_repository.dart';

/// Только явное завершение темы засчитывает активность дня.
class CompleteCourseTopic {
  const CompleteCourseTopic(this._course, this._days);

  final CourseProgressRepository _course;
  final DayProgressRepository _days;

  Future<Result<DayProgress>> call(int topic) async {
    if (topic < 1 || topic > courseTopicCount) {
      return const Failure(
        AppFailure('Некорректный номер темы', kind: FailureKind.unknown),
      );
    }
    final readOn = DateTime.now();
    final saved = await _course.completeTopic(topic);
    if (saved case Failure(failure: final failure)) return Failure(failure);

    // Две записи не атомарны. Повтор безопасен и восстанавливает отметку дня,
    // если она не сохранилась после успешного завершения темы.
    return _days.markRead(CardType.basics, date: readOn);
  }
}
