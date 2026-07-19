import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/daily_card_screen.dart';

class _FakeCardsRepository implements DayCardsRepository {
  @override
  Future<Result<List<DayCard>>> getCardsFor(DateTime date) async => Success([
        const DayCard(
          id: 'quote',
          type: CardType.quote,
          body: 'Первая карточка',
          source: 'Источник 1',
        ),
        const DayCard(
          id: 'advice',
          type: CardType.advice,
          body: 'Последняя карточка',
          source: 'Источник 2',
        ),
      ]);
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

  @override
  Future<Result<DayProgress>> resetToday() async {
    _read = {};
    return Success(_current);
  }

  Set<CardType> get readTypes => _read;
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

    expect(find.text('Первая карточка'), findsOneWidget);
    expect(find.text('Дальше'), findsOneWidget);

    await tester.tap(find.text('Дальше'));
    await settleCard(tester);

    expect(find.text('Последняя карточка'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);

    await tester.tap(find.text('Готово'));
    await settleCard(tester);

    expect(find.textContaining('Мысль дня получена'), findsOneWidget);
    expect(find.text('На главный экран'), findsOneWidget);
  });

  testWidgets('свайп влево листает вперёд и до завершения', (tester) async {
    await tester.pumpWidget(buildApp());
    await settleCard(tester);

    await tester.fling(find.text('Первая карточка'), const Offset(-300, 0), 800);
    await settleCard(tester);
    expect(find.text('Последняя карточка'), findsOneWidget);

    await tester.fling(find.text('Последняя карточка'), const Offset(-300, 0), 800);
    await settleCard(tester);
    expect(find.textContaining('Мысль дня получена'), findsOneWidget);
  });

  testWidgets('свайп вправо возвращает назад, в том числе с завершения',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await settleCard(tester);

    await tester.tap(find.text('Дальше'));
    await settleCard(tester);
    await tester.tap(find.text('Готово'));
    await settleCard(tester);
    expect(find.textContaining('Мысль дня получена'), findsOneWidget);

    await tester.fling(
        find.textContaining('Мысль дня получена'), const Offset(300, 0), 800);
    await settleCard(tester);
    expect(find.text('Последняя карточка'), findsOneWidget);

    await tester.fling(find.text('Последняя карточка'), const Offset(300, 0), 800);
    await settleCard(tester);
    expect(find.text('Первая карточка'), findsOneWidget);
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
}
