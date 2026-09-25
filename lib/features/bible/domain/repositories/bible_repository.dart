import '../../../../core/result/result.dart';
import '../entities/bible_chapter.dart';

abstract interface class BibleRepository {
  Future<Result<BibleChapter>> getChapter(String book, int chapter);
}
