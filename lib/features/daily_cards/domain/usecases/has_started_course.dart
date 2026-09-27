import '../../../../core/result/result.dart';
import '../repositories/course_progress_repository.dart';

class HasStartedCourse {
  const HasStartedCourse(this._repository);
  final CourseProgressRepository _repository;

  Future<Result<bool>> call() => _repository.hasStarted();
}
