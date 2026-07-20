import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/refresh_on_resume.dart';

const _cards = [
  DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
];

/// Считает обращения и всегда отдаёт stale-набор.
class _CountingRepository implements DayCardsRepository {
  int calls = 0;

  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async {
    calls++;
    return Success(
      TodayCards(cards: _cards, staleDate: DateTime(2026, 7, 19)),
    );
  }
}

class _FreshRepository implements DayCardsRepository {
  int calls = 0;

  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async {
    calls++;
    return const Success(TodayCards(cards: _cards));
  }
}

Future<ProviderContainer> pumpWithRepo(
  WidgetTester tester,
  DayCardsRepository repo,
) async {
  final container = ProviderContainer(
    overrides: [dayCardsRepositoryProvider.overrideWithValue(repo)],
  );
  await container.read(todayCardsProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: RefreshOnResume(child: SizedBox.shrink()),
      ),
    ),
  );
  return container;
}

Future<void> resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

void main() {
  testWidgets('возврат в приложение при stale-наборе перезапрашивает карточки',
      (tester) async {
    final repo = _CountingRepository();
    final container = await pumpWithRepo(tester, repo);

    await resume(tester);
    await container.read(todayCardsProvider.future);

    expect(repo.calls, 2);
  });

  testWidgets('возврат при свежем наборе ничего не дёргает', (tester) async {
    final repo = _FreshRepository();
    await pumpWithRepo(tester, repo);

    await resume(tester);

    expect(repo.calls, 1);
  });
}
