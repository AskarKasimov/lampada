// lib/features/daily_cards/presentation/providers/providers.dart
//
// Единственное место, где presentation видит data:
// здесь склеиваются repository → usecase.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../data/repositories/mock_day_cards_repository.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../../domain/usecases/get_today_cards.dart';

final dayCardsRepositoryProvider = Provider<DayCardsRepository>(
  (ref) => const MockDayCardsRepository(),
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
