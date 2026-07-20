import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/daily_card_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/daily_card_action_button.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/session_done_view.dart';

class _FakeCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async =>
      Success(TodayCards(cards: const [
        DayCard(
          id: 'quote',
          type: CardType.quote,
          body: 'Первая карточка',
          source: 'Источник 1',
        ),
        DayCard(
          id: 'advice',
          type: CardType.advice,
          body: 'Последняя карточка',
          source: 'Источник 2',
        ),
      ]));
}

/// In-memory прогресс — экран его читает и обновляет.
class _FakeProgressRepository implements DayProgressRepository {
  Set<CardType> _read = {};
  int _streak = 0;

  DayProgress get _current =>
      DayProgress(readTypes: _read, streakDays: _streak);

  @override
  Future<Result<DayProgress>> loadToday() async => Success(_current);

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    _read = {..._read, type};
    return Success(_current);
  }

  @override
  Future<Result<DayProgress>> completeDay() async {
    _streak += 1;
    return Success(_current);
  }

  Set<CardType> get readTypes => _read;
  int get streakDays => _streak;
}

/// Тот же набор, но помеченный кэшем за другую дату.
class _StaleCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async => Success(
        TodayCards(
          cards: const [
            DayCard(
              id: 'quote',
              type: CardType.quote,
              body: 'Первая карточка',
              source: 'Источник 1',
            ),
            DayCard(
              id: 'advice',
              type: CardType.advice,
              body: 'Последняя карточка',
              source: 'Источник 2',
            ),
          ],
          staleDate: DateTime(2026, 7, 19),
        ),
      );
}

void main() {
  Widget buildApp({DayProgressRepository? progressRepository}) => ProviderScope(
        overrides: [
          dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
          dayProgressRepositoryProvider.overrideWithValue(
            progressRepository ?? _FakeProgressRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const DailyCardScreen()),
      );

  // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
  // никогда не осядет. Прокачиваем ровно на длительность анимации карточки.
  Future<void> settleCard(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('проходит все карточки дня и доходит до экрана завершения',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await settleCard(tester);

    expect(find.byKey(const Key('quote')), findsOneWidget);
    expect(find.byType(DailyCardNextButton), findsOneWidget);

    await tester.tap(find.byType(DailyCardNextButton));
    await settleCard(tester);

    expect(find.byKey(const Key('advice')), findsOneWidget);
    expect(find.byType(DailyCardDoneButton), findsOneWidget);

    await tester.tap(find.byType(DailyCardDoneButton));
    await settleCard(tester);

    expect(find.byType(SessionDoneView), findsOneWidget);
    expect(find.byType(SessionDoneHomeButton), findsOneWidget);
  });

  testWidgets('свайп влево листает вперёд и до завершения', (tester) async {
    await tester.pumpWidget(buildApp());
    await settleCard(tester);

    await tester.fling(find.byKey(const Key('quote')), const Offset(-300, 0), 800);
    await settleCard(tester);
    expect(find.byKey(const Key('advice')), findsOneWidget);

    await tester.fling(find.byKey(const Key('advice')), const Offset(-300, 0), 800);
    await settleCard(tester);
    expect(find.byType(SessionDoneView), findsOneWidget);
  });

  testWidgets('свайп вправо возвращает назад, в том числе с завершения',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await settleCard(tester);

    await tester.tap(find.byType(DailyCardNextButton));
    await settleCard(tester);
    await tester.tap(find.byType(DailyCardDoneButton));
    await settleCard(tester);
    expect(find.byType(SessionDoneView), findsOneWidget);

    await tester.fling(
        find.byType(SessionDoneView), const Offset(300, 0), 800);
    await settleCard(tester);
    expect(find.byKey(const Key('advice')), findsOneWidget);

    await tester.fling(find.byKey(const Key('advice')), const Offset(300, 0), 800);
    await settleCard(tester);
    expect(find.byKey(const Key('quote')), findsOneWidget);
  });

  testWidgets(
      'карточка засчитывается прочитанной сразу при показе, без «Дальше»',
      (tester) async {
    final progressRepo = _FakeProgressRepository();
    await tester.pumpWidget(buildApp(progressRepository: progressRepo));
    await settleCard(tester);

    expect(progressRepo.readTypes, contains(CardType.quote));
    expect(progressRepo.readTypes, isNot(contains(CardType.advice)));
  });

  testWidgets('карточки за другой день: свой done-экран, серия не растёт',
      (tester) async {
    final progress = _FakeProgressRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dayCardsRepositoryProvider.overrideWithValue(_StaleCardsRepository()),
          dayProgressRepositoryProvider.overrideWithValue(progress),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const DailyCardScreen()),
      ),
    );
    await settleCard(tester);

    await tester.tap(find.byType(DailyCardNextButton));
    await settleCard(tester);
    await tester.tap(find.byType(DailyCardDoneButton));
    await settleCard(tester);

    expect(find.byType(SessionDoneStaleView), findsOneWidget);
    // Обещания «огонёк зажжён» тут быть не должно.
    expect(find.byType(SessionDoneView), findsNothing);
    expect(find.text('Это карточки за 19 июля'), findsOneWidget);

    // Прогресс дня не тронут вообще.
    expect(progress.readTypes, isEmpty);
    expect(progress.streakDays, 0);
  });
}
