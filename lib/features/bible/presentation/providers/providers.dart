import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/bible_remote_datasource.dart';
import '../../data/repositories/azbyka_bible_repository.dart';
import '../../domain/bible_chapter_statuses.dart';
import '../../domain/entities/bible_chapter.dart';
import '../../domain/entities/daily_verse.dart';
import '../../domain/repositories/bible_repository.dart';
import '../../domain/usecases/get_bible_chapter.dart';
import '../../domain/usecases/get_verse_of_day.dart';
import '../../domain/usecases/load_bible_chapter_statuses.dart';
import '../../domain/usecases/load_bible_reading_position.dart';
import '../../domain/usecases/mark_bible_chapter_read.dart';
import '../../domain/usecases/save_bible_chapter_progress.dart';
import '../../domain/usecases/save_bible_reading_position.dart';

final bibleRepositoryProvider = Provider<BibleRepository>(
  (ref) => AzbykaBibleRepository(
    AzbykaBibleRemoteDatasource(),
    ref.watch(sharedPreferencesProvider),
  ),
);

final getBibleChapterProvider = Provider<GetBibleChapter>(
  (ref) => GetBibleChapter(ref.watch(bibleRepositoryProvider)),
);

final getVerseOfDayProvider = Provider<GetVerseOfDay>(
  (ref) => GetVerseOfDay(ref.watch(bibleRepositoryProvider)),
);

/// Стих дня по ключу даты `yyyy-MM-dd`: ключ, а не DateTime, чтобы два
/// момента одних суток не давали двух запросов. Повторы сети ограничены
/// бюджетом репозитория, поэтому автоповтор Riverpod выключен.
final verseOfDayProvider = FutureProvider.family<DailyVerse, String>((
  ref,
  dateKey,
) async {
  final result = await ref.watch(getVerseOfDayProvider)(
    DateTime.parse(dateKey),
  );
  return switch (result) {
    Success(value: final verse) => verse,
    Failure(failure: final failure) => throw failure,
  };
}, retry: (_, _) => null);

final loadBibleChapterStatusesProvider = Provider<LoadBibleChapterStatuses>(
  (ref) => LoadBibleChapterStatuses(ref.watch(bibleRepositoryProvider)),
);

final markBibleChapterReadProvider = Provider<MarkBibleChapterRead>(
  (ref) => MarkBibleChapterRead(ref.watch(bibleRepositoryProvider)),
);

final saveBibleChapterProgressProvider = Provider<SaveBibleChapterProgress>(
  (ref) => SaveBibleChapterProgress(ref.watch(bibleRepositoryProvider)),
);

final loadBibleReadingPositionProvider = Provider<LoadBibleReadingPosition>(
  (ref) => LoadBibleReadingPosition(ref.watch(bibleRepositoryProvider)),
);

final saveBibleReadingPositionProvider = Provider<SaveBibleReadingPosition>(
  (ref) => SaveBibleReadingPosition(ref.watch(bibleRepositoryProvider)),
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
