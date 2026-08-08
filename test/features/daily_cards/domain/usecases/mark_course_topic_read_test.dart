import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/repositories/course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/mark_course_topic_read.dart';

class _CourseProgressRepository implements CourseProgressRepository {
  _CourseProgressRepository(this.result);

  final Result<void> result;
  var calls = 0;

  @override
  Future<Result<int>> currentTopic() async => const Success(1);

  @override
  Future<Result<void>> markCurrentTopicRead() async {
    calls++;
    return result;
  }
}

void main() {
  test('передаёт успешную отметку текущей темы репозиторию', () async {
    final repository = _CourseProgressRepository(const Success(null));
    final result = await MarkCourseTopicRead(repository)();

    expect(result, isA<Success<void>>());
    expect(repository.calls, 1);
  });

  test('сохраняет ошибку отметки текущей темы', () async {
    const failure = AppFailure('Ошибка записи', kind: FailureKind.unknown);
    final repository = _CourseProgressRepository(const Failure(failure));
    final result = await MarkCourseTopicRead(repository)();

    expect((result as Failure<void>).failure, same(failure));
    expect(repository.calls, 1);
  });
}
