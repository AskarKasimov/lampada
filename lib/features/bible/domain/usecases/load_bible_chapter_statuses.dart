import '../../../../core/result/result.dart';
import '../bible_chapter_statuses.dart';
import '../repositories/bible_repository.dart';

class LoadBibleChapterStatuses {
  const LoadBibleChapterStatuses(this._repository);

  final BibleRepository _repository;

  Future<Result<BibleChapterStatuses>> call() =>
      _repository.getChapterStatuses();
}
