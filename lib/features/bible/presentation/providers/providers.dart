import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/bible_remote_datasource.dart';
import '../../data/repositories/azbyka_bible_repository.dart';
import '../../domain/bible_chapter_statuses.dart';
import '../../domain/entities/bible_chapter.dart';
import '../../domain/repositories/bible_repository.dart';
import '../../domain/usecases/get_bible_chapter.dart';
import '../../domain/usecases/load_bible_chapter_statuses.dart';
import '../../domain/usecases/mark_bible_chapter_read.dart';
import '../../domain/usecases/save_bible_chapter_progress.dart';

final bibleRepositoryProvider = Provider<BibleRepository>(
  (ref) => AzbykaBibleRepository(
    AzbykaBibleRemoteDatasource(),
    ref.watch(sharedPreferencesProvider),
  ),
);

final getBibleChapterProvider = Provider<GetBibleChapter>(
  (ref) => GetBibleChapter(ref.watch(bibleRepositoryProvider)),
);

final loadBibleChapterStatusesProvider = Provider<LoadBibleChapterStatuses>(
  (ref) => LoadBibleChapterStatuses(ref.watch(bibleRepositoryProvider)),
);

final markBibleChapterReadProvider = Provider<MarkBibleChapterRead>(
  (ref) => MarkBibleChapterRead(ref.watch(bibleRepositoryProvider)),
);

final saveBibleChapterProgressProvider = Provider<SaveBibleChapterProgress>(
  (ref) => SaveBibleChapterProgress(ref.watch(bibleRepositoryProvider)),
);

final bibleChapterStatusesProvider =
    AsyncNotifierProvider<BibleChapterStatusesNotifier, BibleChapterStatuses>(
      BibleChapterStatusesNotifier.new,
    );

class BibleChapterStatusesNotifier extends AsyncNotifier<BibleChapterStatuses> {
  int _revision = 0;

  @override
  Future<BibleChapterStatuses> build() async {
    final result = await ref.read(loadBibleChapterStatusesProvider)();
    return switch (result) {
      Success(value: final statuses) => statuses,
      Failure(failure: final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    final revision = ++_revision;
    final result = await ref.read(loadBibleChapterStatusesProvider)();
    if (result case Success(value: final statuses)) {
      if (revision != _revision) return;
      state = AsyncData(statuses);
    }
  }

  Future<void> saveProgress(
    String book,
    int chapter,
    BibleChapterProgress progress,
  ) async {
    _revision++;
    final result = await ref.read(saveBibleChapterProgressProvider)(
      book,
      chapter,
      progress,
    );
    if (result is Success) await refresh();
  }

  Future<void> markRead(String book, int chapter) async {
    _revision++;
    final result = await ref.read(markBibleChapterReadProvider)(book, chapter);
    if (result is Success) await refresh();
  }
}

final bibleChapterProvider = FutureProvider.family<BibleChapter, (String, int)>(
  (ref, key) async {
    final result = await ref.watch(getBibleChapterProvider)(key.$1, key.$2);
    return switch (result) {
      Success(value: final chapter) => chapter,
      Failure(failure: final failure) => throw failure,
    };
  },
);

/// Запрос открыть главу во вкладке «Библия», например из «Мудрости дня».
/// [serial] отличает повторный запрос той же главы от уже выполненного.
typedef BibleOpenRequest = ({String book, int chapter, int serial});

/// Последний запрос главы. Шелл по нему переключается на «Библию», вкладка
/// открывает главу с первого стиха. Отдельного окна с главой нет.
final bibleOpenRequestProvider =
    NotifierProvider<BibleOpenRequestNotifier, BibleOpenRequest?>(
      BibleOpenRequestNotifier.new,
    );

class BibleOpenRequestNotifier extends Notifier<BibleOpenRequest?> {
  @override
  BibleOpenRequest? build() => null;

  void open(String book, int chapter) =>
      state = (book: book, chapter: chapter, serial: (state?.serial ?? 0) + 1);
}
