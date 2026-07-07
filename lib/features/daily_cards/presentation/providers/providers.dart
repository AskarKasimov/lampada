// lib/features/daily_cards/presentation/providers/providers.dart
//
// Единственное место, где presentation видит data:
// здесь склеиваются datasource → repository → usecase.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../data/datasources/day_cards_remote_datasource.dart';
import '../../data/repositories/day_cards_repository_impl.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../../domain/usecases/get_today_cards.dart';

final dayCardsDatasourceProvider = Provider<DayCardsRemoteDatasource>(
  (ref) => MockDayCardsRemoteDatasource(),
);

final dayCardsRepositoryProvider = Provider<DayCardsRepository>(
  (ref) => DayCardsRepositoryImpl(ref.watch(dayCardsDatasourceProvider)),
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
