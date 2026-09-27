import '../../../../core/result/result.dart';
import '../bible_chapter_statuses.dart';
import '../entities/bible_chapter.dart';

abstract interface class BibleRepository {
  Future<Result<BibleChapter>> getChapter(String book, int chapter);
  Future<Result<BibleChapterStatuses>> getChapterStatuses();
  Future<Result<void>> markChapterRead(String book, int chapter);
  Future<Result<void>> saveChapterProgress(
    String book,
    int chapter,
    BibleChapterProgress progress,
  );
}
