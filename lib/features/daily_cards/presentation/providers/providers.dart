//
// Единственное место, где presentation видит data:
// здесь склеиваются repository → usecase и провайдер прогресса.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../data/datasources/day_cards_remote_datasource.dart';
import '../../data/repositories/azbyka_day_cards_repository.dart';
import '../../data/repositories/prefs_day_progress_repository.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/entities/today_cards.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../../domain/repositories/day_progress_repository.dart';
import '../../domain/usecases/complete_day.dart';
import '../../domain/usecases/get_today_cards.dart';
import '../../domain/usecases/record_card_read.dart';

final dayCardsRepositoryProvider = Provider<DayCardsRepository>(
  (ref) => AzbykaDayCardsRepository(
    AzbykaDayCardsRemoteDatasource(),
    ref.watch(sharedPreferencesProvider),
  ),
);

final getTodayCardsProvider = Provider<GetTodayCards>(
  (ref) => GetTodayCards(ref.watch(dayCardsRepositoryProvider)),
);

/// Карточки сегодняшнего дня в порядке показа.
final todayCardsProvider = FutureProvider<TodayCards>((ref) async {
  final result = await ref.watch(getTodayCardsProvider)(DateTime.now());
  return switch (result) {
    Success(value: final today) => today,
    Failure(failure: final f) => throw f,
  };
});

/// Инициализируется в main() через override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override sharedPreferencesProvider in main()'),
);

final dayProgressRepositoryProvider = Provider<DayProgressRepository>(
  (ref) => PrefsDayProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final recordCardReadProvider = Provider<RecordCardRead>(
  (ref) => RecordCardRead(ref.watch(dayProgressRepositoryProvider)),
);

final completeDayProvider = Provider<CompleteDay>(
  (ref) => CompleteDay(ref.watch(dayProgressRepositoryProvider)),
);

/// Прогресс текущего дня. Экраны читают состояние и вызывают методы
/// markRead/completeDay — репозиторий напрямую не трогают.
final dayProgressProvider =
    AsyncNotifierProvider<DayProgressNotifier, DayProgress>(
  DayProgressNotifier.new,
);

class DayProgressNotifier extends AsyncNotifier<DayProgress> {
  DayProgressRepository get _repo => ref.read(dayProgressRepositoryProvider);

  /// Набор, по которому сейчас идёт сессия. Null — карточки ещё не загрузились
  /// или упали; записывать в прогресс тогда нечего.
  TodayCards? get _session => ref.read(todayCardsProvider).value;

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

  /// Решение «засчитывать ли сессию» принимает usecase, не нотифаер: это
  /// доменное правило, и жить оно должно там же, где его можно проверить без
  /// Riverpod. Здесь остаётся только проводка.
  Future<void> markRead(CardType type) async {
    final session = _session;
    if (session == null) return;
    await _apply(
      ref.read(recordCardReadProvider)(type, session: session),
    );
  }

  Future<void> completeDay() async {
    final session = _session;
    if (session == null) return;
    await _apply(ref.read(completeDayProvider)(session: session));
  }
}
