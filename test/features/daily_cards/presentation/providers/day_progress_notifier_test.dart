import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cards = [
  DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
  DayCard(id: 'qu', type: CardType.question, body: 'b', source: 's'),
  DayCard(id: 'a', type: CardType.advice, body: 'b', source: 's'),
  DayCard(id: 'ba', type: CardType.basics, body: 'b', source: 's'),
  DayCard(id: 'r', type: CardType.reading, body: 'b', source: 's'),
];

class _StaleCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async =>
      Success(TodayCards(cards: _cards, staleDate: DateTime(2026, 7, 19)));
}

class _FreshCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async =>
      const Success(TodayCards(cards: _cards));
}

Future<ProviderContainer> _container(DayCardsRepository cards) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      dayCardsRepositoryProvider.overrideWithValue(cards),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  await container.read(todayCardsProvider.future);
  await container.read(dayProgressProvider.future);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('свежие карточки: чтение засчитывается, серия растёт', () async {
    final container = await _container(_FreshCardsRepository());
    final notifier = container.read(dayProgressProvider.notifier);

    for (final card in _cards) {
      await notifier.markRead(card.type);
    }
    await notifier.completeDay();

    final progress = container.read(dayProgressProvider).requireValue;
    expect(progress.allRead, isTrue);
    expect(progress.streakDays, 1);
  });

  test('карточки за другой день: ни прогресс, ни серия не двигаются', () async {
    final container = await _container(_StaleCardsRepository());
    final notifier = container.read(dayProgressProvider.notifier);

    for (final card in _cards) {
      await notifier.markRead(card.type);
    }
    await notifier.completeDay();

    // Сегодняшний контент юзер не видел — день не пройден.
    final progress = container.read(dayProgressProvider).requireValue;
    expect(progress.readCount, 0);
    expect(progress.streakDays, 0);
  });

  test('stale-сессия ничего не пишет в shared_preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        dayCardsRepositoryProvider
            .overrideWithValue(_StaleCardsRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    await container.read(todayCardsProvider.future);
    await container.read(dayProgressProvider.future);

    await container.read(dayProgressProvider.notifier).completeDay();

    expect(prefs.getString('day_progress'), isNull);
  });
}
