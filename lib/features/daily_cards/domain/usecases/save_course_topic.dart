import '../../../../core/result/result.dart';
import '../repositories/course_progress_repository.dart';

class SaveCourseTopic {
  const SaveCourseTopic(this._repository);

  final CourseProgressRepository _repository;

  Future<Result<void>> call(int topic, {int page = 0}) =>
      _repository.saveCurrentTopic(topic, page: page);
}
