import '../../../../core/result/result.dart';
import '../entities/bible_chapter.dart';
import '../repositories/bible_repository.dart';

class GetBibleChapter {
  const GetBibleChapter(this._repository);

  final BibleRepository _repository;

  Future<Result<BibleChapter>> call(String book, int chapter) =>
      _repository.getChapter(book, chapter);
}
