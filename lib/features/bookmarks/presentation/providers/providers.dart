// Единственное место, где presentation фичи видит data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/repositories/prefs_bookmarks_repository.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmarks_repository.dart';
import '../../domain/usecases/manage_bookmarks.dart';

final bookmarksRepositoryProvider = Provider<BookmarksRepository>(
  (ref) => PrefsBookmarksRepository(ref.watch(sharedPreferencesProvider)),
);

final loadBookmarksProvider = Provider<LoadBookmarks>(
  (ref) => LoadBookmarks(ref.watch(bookmarksRepositoryProvider)),
);

final toggleBookmarkProvider = Provider<ToggleBookmark>(
  (ref) => ToggleBookmark(ref.watch(bookmarksRepositoryProvider)),
);

final removeBookmarkProvider = Provider<RemoveBookmark>(
  (ref) => RemoveBookmark(ref.watch(bookmarksRepositoryProvider)),
);

final bookmarksProvider =
    AsyncNotifierProvider<BookmarksNotifier, List<Bookmark>>(
      BookmarksNotifier.new,
    );

class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() async {
    final result = await ref.read(loadBookmarksProvider)();
    return switch (result) {
      Success(value: final list) => list,
      Failure(failure: final f) => throw f,
    };
  }

  bool isSaved(String id) => (state.value ?? const []).any((b) => b.id == id);

  Future<bool> toggle(Bookmark bookmark) => _apply(
    ref.read(toggleBookmarkProvider)(bookmark, isSaved: isSaved(bookmark.id)),
  );

  Future<bool> remove(String id) =>
      _apply(ref.read(removeBookmarkProvider)(id));

  /// При неудаче оставляем предыдущий список на экране: локальный сбой не
  /// должен превращать «Копилку» в пустое состояние и стирать контекст.
  Future<bool> _apply(Future<Result<List<Bookmark>>> op) async {
    switch (await op) {
      case Success(value: final list):
        state = AsyncData(list);
        return true;
      case Failure():
        return false;
    }
  }
}
