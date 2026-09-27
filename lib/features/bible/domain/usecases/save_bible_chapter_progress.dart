import '../../../../core/result/result.dart';
import '../bible_chapter_statuses.dart';
import '../repositories/bible_repository.dart';

class SaveBibleChapterProgress {
  const SaveBibleChapterProgress(this._repository);

  final BibleRepository _repository;

  Future<Result<void>> call(
    String book,
    int chapter,
    BibleChapterProgress progress,
  ) => _repository.saveChapterProgress(book, chapter, progress);
}
