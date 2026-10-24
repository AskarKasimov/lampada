// Единственное место, где presentation видит data: тут repository → usecase
// и провайдер прогресса склеиваются в DI-граф.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/format/date_key.dart';
import '../../../../core/log/net_log.dart';
import '../../../../core/network/network_status_provider.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/day_cards_remote_datasource.dart';
import '../../data/repositories/azbyka_day_cards_repository.dart';
import '../../data/repositories/prefs_course_progress_repository.dart';
import '../../data/repositories/prefs_day_progress_repository.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/entities/day_section.dart';
import '../../domain/entities/today_cards.dart';
import '../../domain/repositories/course_progress_repository.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../../domain/repositories/day_progress_repository.dart';
import '../../domain/usecases/complete_course_topic.dart';
import '../../domain/usecases/complete_day_wisdom.dart';
import '../../domain/usecases/get_completed_course_topics.dart';
import '../../domain/usecases/get_course_page.dart';
import '../../domain/usecases/get_course_topic.dart';
import '../../domain/usecases/get_today_cards.dart';
import '../../domain/usecases/has_started_course.dart';
import '../../domain/usecases/load_day_progress.dart';
import '../../domain/usecases/record_card_read.dart';
import '../../domain/usecases/save_course_topic.dart';

final dayCardsRepositoryProvider = Provider<DayCardsRepository>(
  (ref) => AzbykaDayCardsRepository(
    AzbykaDayCardsRemoteDatasource(),
    ref.watch(sharedPreferencesProvider),
    networkStatus: ref.watch(networkStatusProvider),
  ),
);

final getTodayCardsProvider = Provider<GetTodayCards>(
  (ref) => GetTodayCards(ref.watch(dayCardsRepositoryProvider)),
);

/// Карточки произвольного дня. Ключ — `yyyy-MM-dd`, а не DateTime: у family
/// ключ сравнивается по значению, а два DateTime одной даты с разным временем
/// дали бы два разных запроса.
final dayCardsProvider = FutureProvider.family<TodayCards, String>((
  ref,
  dateKey,
) async {
  final result = await ref.watch(getTodayCardsProvider)(
    DateTime.parse(dateKey),
  );
  return switch (result) {
    Success(value: final day) => day,
    Failure(failure: final f) => throw f,
  };
});

/// Карточки сегодняшнего дня. Обёртка над [dayCardsProvider], а не свой
/// запрос: иначе «Сегодня» и прогресс тянули бы одну и ту же дату дважды.
final todayCardsProvider = FutureProvider<TodayCards>(
  (ref) => ref.watch(dayCardsProvider(dateKey(DateTime.now())).future),
);

/// Разовая просьба открыть раздел сегодняшнего дня, как только он готов.
/// Её оставляют приветствие («Открыть сегодняшний день» обещает чтение, а
/// не главную) и нажатие на напоминание (оно зовёт в конкретный раздел).
final openDaySectionRequestProvider =
    NotifierProvider<OpenDaySectionRequestNotifier, SectionRequest?>(
      OpenDaySectionRequestNotifier.new,
    );

/// Кто попросил открыть раздел: аналитика различает переход из
/// приветствия и из напоминания.
enum SectionRequestOrigin { onboarding, notification }

typedef SectionRequest = ({DaySection section, SectionRequestOrigin origin});

class OpenDaySectionRequestNotifier extends Notifier<SectionRequest?> {
  @override
  SectionRequest? build() => null;

  void request(DaySection section, {required SectionRequestOrigin origin}) =>
      state = (section: section, origin: origin);

  /// Снимает просьбу о [section] и возвращает её источник, если она была:
  /// раздел должен открыть ровно один экран.
  SectionRequestOrigin? consume(DaySection section) {
    final pending = state;
    if (pending == null || pending.section != section) return null;
    state = null;
    return pending.origin;
  }
}

final dayProgressRepositoryProvider = Provider<DayProgressRepository>(
  (ref) => PrefsDayProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final recordCardReadProvider = Provider<RecordCardRead>(
  (ref) => RecordCardRead(ref.watch(dayProgressRepositoryProvider)),
);

final completeDayWisdomProvider = Provider<CompleteDayWisdom>(
  (ref) => CompleteDayWisdom(ref.watch(dayProgressRepositoryProvider)),
);

final loadDayProgressProvider = Provider<LoadDayProgress>(
  (ref) => LoadDayProgress(ref.watch(dayProgressRepositoryProvider)),
);

final courseProgressRepositoryProvider = Provider<CourseProgressRepository>(
  (ref) => PrefsCourseProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final hasStartedCourseUseCaseProvider = Provider<HasStartedCourse>(
  (ref) => HasStartedCourse(ref.watch(courseProgressRepositoryProvider)),
);

final hasStartedCourseProvider = FutureProvider<bool>((ref) async {
  final result = await ref.watch(hasStartedCourseUseCaseProvider)();
  return switch (result) {
    Success(value: final started) => started,
    Failure(failure: final failure) => throw failure,
  };
});

final getCourseTopicProvider = Provider<GetCourseTopic>(
  (ref) => GetCourseTopic(
    ref.watch(courseProgressRepositoryProvider),
    ref.watch(dayCardsRepositoryProvider),
  ),
);

final getCoursePageProvider = Provider<GetCoursePage>(
  (ref) => GetCoursePage(ref.watch(courseProgressRepositoryProvider)),
);

final coursePageProvider = FutureProvider.family<int, int>((ref, topic) async {
  final result = await ref.watch(getCoursePageProvider)(topic);
  return switch (result) {
    Success(value: final page) => page ?? 0,
    Failure(failure: final failure) => throw failure,
  };
});

final saveCourseTopicProvider = Provider<SaveCourseTopic>(
  (ref) => SaveCourseTopic(ref.watch(courseProgressRepositoryProvider)),
);

final getCompletedCourseTopicsProvider = Provider<GetCompletedCourseTopics>(
  (ref) =>
      GetCompletedCourseTopics(ref.watch(courseProgressRepositoryProvider)),
);

final completeCourseTopicProvider = Provider<CompleteCourseTopic>(
  (ref) => CompleteCourseTopic(
    ref.watch(courseProgressRepositoryProvider),
    ref.watch(dayProgressRepositoryProvider),
  ),
);

final completedCourseTopicsProvider = FutureProvider<Set<int>>((ref) async {
  final result = await ref.watch(getCompletedCourseTopicsProvider)();
  return switch (result) {
    Success(value: final topics) => topics,
    Failure(failure: final failure) => throw failure,
  };
});

/// Карточка «Основы» для текущей темы курса.
///
/// Null вместо ошибки: экран остаётся доступен, а в качестве запасного
/// содержимого экран дня показывает календарные «Основы».
final courseTopicProvider = FutureProvider<DayCard?>((ref) async {
  final result = await ref.watch(getCourseTopicProvider)();
  return switch (result) {
    Success(value: final card) => card,
    Failure(failure: final f) => () {
      netLog('курс не доехал, оставляем основы дня: $f');
      return null;
    }(),
  };
});

/// Карточка «Основы» для страницы с явно запрошенным номером темы.
///
/// Ошибку отдельной страницы оставляем локальной: одна недоступная старая
/// тема не должна подменяться карточкой другого дня.
final courseTopicByNumberProvider = FutureProvider.family<DayCard, int>(
  (ref, topic) async {
    final result = await ref.watch(getCourseTopicProvider).forTopic(topic);
    return switch (result) {
      Success(value: final card) => card,
      Failure(failure: final f) => () {
        netLog('тема курса $topic не доехала: $f');
        throw f;
      }(),
    };
  },
  // Здесь retry управляется кнопкой конкретной исторической страницы.
  retry: (_, _) => null,
);

/// Прогресс дня: экраны вызывают markRead, репозиторий напрямую не трогают.
final dayProgressProvider =
    AsyncNotifierProvider<DayProgressNotifier, DayProgress>(
      DayProgressNotifier.new,
    );

class DayProgressNotifier extends AsyncNotifier<DayProgress> {
  /// Набор, по которому сейчас идёт сессия. Null — карточки ещё не загрузились
  /// или упали; записывать в прогресс тогда нечего.
  ///
  /// Читаем инстанс family напрямую, а не обёртку [todayCardsProvider]:
  /// обёртку никто не watch-ит, поэтому она вечно висела бы в loading,
  /// и прогресс молча не записывался бы.
  TodayCards? get _session =>
      ref.read(dayCardsProvider(dateKey(DateTime.now()))).value;

  @override
  Future<DayProgress> build() async {
    final result = await ref.read(loadDayProgressProvider)();
    return switch (result) {
      Success(value: final p) => p,
      Failure(failure: final f) => throw f,
    };
  }

  Future<bool> _apply(Future<Result<DayProgress>> op) async {
    switch (await op) {
      case Success(value: final p):
        state = AsyncData(p);
        return true;
      case Failure(failure: final f):
        netLog('не удалось сохранить прогресс дня: $f');
        return false;
    }
  }

  /// Решение «засчитывать ли сессию» — за usecase, не нотифаером: доменное
  /// правило должно жить там, где его можно проверить без Riverpod.
  Future<bool> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) async {
    if (markVisited && _session == null) return false;
    final day = date ?? DateTime.now();
    final wasRead = state.value?.isReadOn(day, type) ?? true;
    final saved = await _apply(
      ref.read(recordCardReadProvider)(
        type,
        date: date,
        markVisited: markVisited,
      ),
    );
    // Тема курса пишет своё событие; здесь только карточки «Мудрости».
    if (saved && !wasRead && type != CardType.basics) {
      ref
          .read(analyticsProvider)
          .log(
            AnalyticsEvent.cardRead(
              cardType: type.name,
              dayOffset: dayOffset(day),
            ),
          );
    }
    return saved;
  }

  /// Отмечает «Мудрость дня» дочитанной и, при [markVisited], зажигает
  /// «Лампадку». Сессия здесь не проверяется: экран итога открывается только
  /// из уже показанных карточек.
  Future<bool> completeWisdom({DateTime? date, bool markVisited = true}) =>
      _apply(
        ref.read(completeDayWisdomProvider)(
          date: date,
          markVisited: markVisited,
        ),
      );
}
