import '../../../../core/result/result.dart';
import '../repositories/bible_repository.dart';

class MarkBibleChapterRead {
  const MarkBibleChapterRead(this._repository);

  final BibleRepository _repository;

  Future<Result<void>> call(String book, int chapter) =>
      _repository.markChapterRead(book, chapter);
}
