import '../../../../core/result/result.dart';
import '../repositories/course_progress_repository.dart';

class MarkCourseTopicRead {
  const MarkCourseTopicRead(this._repository);

  final CourseProgressRepository _repository;

  Future<Result<void>> call() => _repository.markCurrentTopicRead();
}
