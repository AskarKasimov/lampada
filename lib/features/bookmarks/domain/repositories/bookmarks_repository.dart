import '../../../../core/result/result.dart';
import '../entities/bookmark.dart';

abstract interface class BookmarksRepository {
  /// Свежие сверху — копилка читается как лента, а не как архив.
  Future<Result<List<Bookmark>>> load();

  Future<Result<List<Bookmark>>> save(Bookmark bookmark);

  Future<Result<List<Bookmark>>> remove(String id);
}
