// Единственное место, где presentation фичи видит data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/log/net_log.dart';
import '../../../../core/network/network_status_provider.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/day_story_remote_datasource.dart';
import '../../data/repositories/azbyka_day_story_repository.dart';
import '../../data/repositories/prefs_story_progress_repository.dart';
import '../../domain/entities/day_story.dart';
import '../../domain/entities/story_progress.dart';
import '../../domain/repositories/day_story_repository.dart';
import '../../domain/repositories/story_progress_repository.dart';
import '../../domain/usecases/get_day_story.dart';
import '../../domain/usecases/story_progress.dart';

final dayStoryRepositoryProvider = Provider<DayStoryRepository>(
  (ref) => AzbykaDayStoryRepository(
    AzbykaDayStoryRemoteDatasource(),
    ref.watch(sharedPreferencesProvider),
    networkStatus: ref.watch(networkStatusProvider),
  ),
);

final getDayStoryProvider = Provider<GetDayStory>(
  (ref) => GetDayStory(ref.watch(dayStoryRepositoryProvider)),
);

/// Рассказ по ссылке праздника/святого. Family, а не единичный провайдер:
/// у каждого дня своя ссылка, и смена дня не перечитывает прежний рассказ.
final dayStoryProvider = FutureProvider.family<DayStory, String>(
  (ref, url) async {
    final result = await ref.watch(getDayStoryProvider)(url);
    return switch (result) {
      Success(value: final story) => story,
      Failure(failure: final f) => throw f,
    };
  },
  // Повтор уже сделан внутри репозитория (свой бюджет и расписание) —
  // без отключения риверпод повторял бы retryDelays поверх retryDelays.
  retry: (_, _) => null,
);

final storyProgressRepositoryProvider = Provider<StoryProgressRepository>(
  (ref) => PrefsStoryProgressRepository(ref.watch(sharedPreferencesProvider)),
);

/// Прочитанные рассказы «Памяти дня»: по дням и по святым.
final storyProgressProvider =
    AsyncNotifierProvider<StoryProgressNotifier, StoryProgress>(
      StoryProgressNotifier.new,
    );

class StoryProgressNotifier extends AsyncNotifier<StoryProgress> {
  StoryProgressRepository get _repository =>
      ref.read(storyProgressRepositoryProvider);

  @override
  Future<StoryProgress> build() async {
    final result = await LoadStoryProgress(_repository)();
    return switch (result) {
      Success(value: final progress) => progress,
      Failure(failure: final f) => throw f,
    };
  }

  Future<void> markRead(DateTime date, String storyUrl) async {
    switch (await MarkStoryRead(_repository)(date, storyUrl)) {
      case Success(value: final progress):
        state = AsyncData(progress);
      case Failure(failure: final f):
        // Без отметки придёт лишнее напоминание; чтение это не ломает.
        netLog('не удалось отметить рассказ прочитанным: $f');
    }
  }
}
