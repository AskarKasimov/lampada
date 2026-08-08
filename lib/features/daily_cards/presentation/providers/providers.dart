// Единственное место, где presentation видит data: тут repository → usecase
// и провайдер прогресса склеиваются в DI-граф.
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../domain/entities/today_cards.dart';
import '../../domain/repositories/course_progress_repository.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../../domain/repositories/day_progress_repository.dart';
import '../../domain/usecases/get_course_topic.dart';
import '../../domain/usecases/get_today_cards.dart';
import '../../domain/usecases/load_day_progress.dart';
import '../../domain/usecases/mark_course_topic_read.dart';
import '../../domain/usecases/record_card_read.dart';

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

/// Дата, открытая на вкладке «Сегодня». Полоска недели переключает её,
/// вкладка целиком следует за ней. Нормализована до полуночи, чтобы
/// сравнения дат не зависели от времени суток.
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class SelectedDateNotifier extends Notifier<DateTime> {
  static DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  DateTime build() => _atMidnight(DateTime.now());

  void select(DateTime date) => state = _atMidnight(date);
}

final dayProgressRepositoryProvider = Provider<DayProgressRepository>(
  (ref) => PrefsDayProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final recordCardReadProvider = Provider<RecordCardRead>(
  (ref) => RecordCardRead(ref.watch(dayProgressRepositoryProvider)),
);

final loadDayProgressProvider = Provider<LoadDayProgress>(
  (ref) => LoadDayProgress(ref.watch(dayProgressRepositoryProvider)),
);

final courseProgressRepositoryProvider = Provider<CourseProgressRepository>(
  (ref) => PrefsCourseProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final getCourseTopicProvider = Provider<GetCourseTopic>(
  (ref) => GetCourseTopic(
    ref.watch(courseProgressRepositoryProvider),
    ref.watch(dayCardsRepositoryProvider),
  ),
);

final markCourseTopicReadProvider = Provider<MarkCourseTopicRead>(
  (ref) => MarkCourseTopicRead(ref.watch(courseProgressRepositoryProvider)),
);

/// Карточка «Основы» для текущей темы курса.
///
/// Null вместо ошибки: если личная тема не доехала, экран остаётся доступен,
/// а календарные «Основы» не выдаются за последовательный курс.
final courseTopicProvider = FutureProvider<DayCard?>((ref) async {
  final result = await ref.watch(getCourseTopicProvider)();
  return switch (result) {
    Success(value: final card) => card,
    Failure(failure: final f) => () {
      netLog('курс не доехал, скрываем личную тему: $f');
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
  Future<bool> markRead(CardType type) async {
    final session = _session;
    if (session == null) return false;
    final saved = await _apply(ref.read(recordCardReadProvider)(type));
    if (type == CardType.basics) {
      final result = await ref.read(markCourseTopicReadProvider)();
      if (result is Success<void>) {
        ref.invalidate(courseTopicProvider);
      } else {
        netLog('не удалось отметить тему курса прочитанной: $result');
        return false;
      }
    }
    return saved;
  }
}
