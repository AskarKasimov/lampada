import '../../../../core/result/result.dart';
import '../entities/bookmark.dart';
import '../repositories/bookmarks_repository.dart';

class LoadBookmarks {
  const LoadBookmarks(this._repository);

  final BookmarksRepository _repository;

  Future<Result<List<Bookmark>>> call() => _repository.load();
}

/// Одна кнопка на карточке — одно действие: сохранить или снять.
/// Решение «что сейчас произойдёт» доменное, поэтому живёт здесь, а не в UI.
class ToggleBookmark {
  const ToggleBookmark(this._repository);

  final BookmarksRepository _repository;

  Future<Result<List<Bookmark>>> call(
    Bookmark bookmark, {
    required bool isSaved,
  }) =>
      isSaved ? _repository.remove(bookmark.id) : _repository.save(bookmark);
}

class RemoveBookmark {
  const RemoveBookmark(this._repository);

  final BookmarksRepository _repository;

  Future<Result<List<Bookmark>>> call(String id) => _repository.remove(id);
}
