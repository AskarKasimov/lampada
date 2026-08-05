// Единственное место, где presentation видит data: тут repository → usecase
// и провайдер прогресса склеиваются в DI-граф.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/log/net_log.dart';
import '../../../../core/network/network_status_provider.dart';
import '../../../../core/result/result.dart';
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

/// Инициализируется в main() через override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('override sharedPreferencesProvider in main()'),
);

final dayProgressRepositoryProvider = Provider<DayProgressRepository>(
  (ref) => PrefsDayProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final recordCardReadProvider = Provider<RecordCardRead>(
  (ref) => RecordCardRead(ref.watch(dayProgressRepositoryProvider)),
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
  DayProgressRepository get _repo => ref.read(dayProgressRepositoryProvider);

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
    final result = await _repo.loadToday();
    return switch (result) {
      Success(value: final p) => p,
      Failure(failure: final f) => throw f,
    };
  }

  Future<void> _apply(Future<Result<DayProgress>> op) async {
    switch (await op) {
      case Success(value: final p):
        state = AsyncData(p);
      case Failure(failure: final f):
        state = AsyncError(f, StackTrace.current);
    }
  }

  /// Решение «засчитывать ли сессию» — за usecase, не нотифаером: доменное
  /// правило должно жить там, где его можно проверить без Riverpod.
  Future<void> markRead(CardType type) async {
    final session = _session;
    if (session == null) return;
    await _apply(ref.read(recordCardReadProvider)(type, session: session));
    // Прочитали «Основы» — курс сдвигается на следующую тему, но не чаще
    // раза в день: это тема в день, а не тема за каждое открытие карточки.
    if (type == CardType.basics && session.staleDate == null) {
      await ref.read(courseProgressRepositoryProvider).advanceForToday();
      ref.invalidate(courseTopicProvider);
    }
  }
}
