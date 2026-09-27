import '../../../../core/result/result.dart';
import '../repositories/course_progress_repository.dart';

class GetCoursePage {
  const GetCoursePage(this._repository);
  final CourseProgressRepository _repository;

  Future<Result<int?>> call(int topic) => _repository.currentPage(topic);
}
