import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/repositories/course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/save_course_topic.dart';

class _CourseProgressRepository implements CourseProgressRepository {
  _CourseProgressRepository(this.result);

  final Result<void> result;
  final savedTopics = <int>[];

  @override
  Future<Result<int>> currentTopic() async => const Success(1);

  @override
  Future<Result<void>> saveCurrentTopic(int topic) async {
    savedTopics.add(topic);
    return result;
  }
}

void main() {
  test('передаёт номер открытой темы репозиторию', () async {
    final repository = _CourseProgressRepository(const Success(null));
    final result = await SaveCourseTopic(repository)(12);

    expect(result, isA<Success<void>>());
    expect(repository.savedTopics, [12]);
  });

  test('сохраняет ошибку записи выбранной темы', () async {
    const failure = AppFailure('Ошибка записи', kind: FailureKind.unknown);
    final repository = _CourseProgressRepository(const Failure(failure));
    final result = await SaveCourseTopic(repository)(12);

    expect((result as Failure<void>).failure, same(failure));
    expect(repository.savedTopics, [12]);
  });
}
