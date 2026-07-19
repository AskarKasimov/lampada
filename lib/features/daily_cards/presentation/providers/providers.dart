// lib/features/daily_cards/presentation/providers/providers.dart
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
import '../../domain/repositories/day_cards_repository.dart';
import '../../domain/repositories/day_progress_repository.dart';
import '../../domain/usecases/get_today_cards.dart';

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
final todayCardsProvider = FutureProvider<List<DayCard>>((ref) async {
  final result = await ref.watch(getTodayCardsProvider)(DateTime.now());
  return switch (result) {
    Success(value: final cards) => cards,
    // TODO: человечный экран ошибки вместо проброса.
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

/// Прогресс текущего дня. Экраны читают состояние и вызывают методы
/// markRead/completeDay — репозиторий напрямую не трогают.
final dayProgressProvider =
    AsyncNotifierProvider<DayProgressNotifier, DayProgress>(
  DayProgressNotifier.new,
);

class DayProgressNotifier extends AsyncNotifier<DayProgress> {
  DayProgressRepository get _repo => ref.read(dayProgressRepositoryProvider);

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

  Future<void> markRead(CardType type) => _apply(_repo.markRead(type));
  Future<void> completeDay() => _apply(_repo.completeDay());
}
