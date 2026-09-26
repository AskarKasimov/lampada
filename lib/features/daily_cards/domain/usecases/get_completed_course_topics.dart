import '../../../../core/result/result.dart';
import '../repositories/course_progress_repository.dart';

class GetCompletedCourseTopics {
  const GetCompletedCourseTopics(this._repository);

  final CourseProgressRepository _repository;

  Future<Result<Set<int>>> call() => _repository.completedTopics();
}
