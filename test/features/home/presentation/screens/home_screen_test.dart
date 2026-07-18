// test/features/home/presentation/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/home/presentation/screens/home_screen.dart';

class _FakeCardsRepository implements DayCardsRepository {
  @override
  Future<Result<List<DayCard>>> getCardsFor(DateTime date) async => Success([
        const DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
        const DayCard(id: 'a', type: CardType.advice, body: 'b', source: 's'),
        const DayCard(id: 'ba', type: CardType.basics, body: 'b', source: 's'),
        const DayCard(id: 'r', type: CardType.reading, body: 'b', source: 's'),
      ]);
}

class _FakeProgressRepository implements DayProgressRepository {
  _FakeProgressRepository(this._progress);
  final DayProgress _progress;

  @override
  Future<Result<DayProgress>> loadToday() async => Success(_progress);
  @override
  Future<Result<DayProgress>> markRead(CardType type) async =>
      Success(_progress);
  @override
  Future<Result<DayProgress>> completeDay() async => Success(_progress);
  @override
  Future<Result<DayProgress>> resetToday() async => Success(_progress);
}

void main() {
  Widget buildApp(DayProgress progress) => ProviderScope(
        overrides: [
          dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
          dayProgressRepositoryProvider
              .overrideWithValue(_FakeProgressRepository(progress)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      );

  testWidgets('ничего не прочитано — CTA «Начать» и серия', (tester) async {
    await tester.pumpWidget(
      buildApp(const DayProgress(readTypes: {}, streakDays: 12)),
    );
    await tester.pump();

    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('Текущая серия 12 дней'), findsOneWidget);
    expect(find.text('Цитата'), findsOneWidget);
  });

  testWidgets('часть прочитана — CTA «Продолжить»', (tester) async {
    await tester.pumpWidget(
      buildApp(const DayProgress(readTypes: {CardType.quote}, streakDays: 3)),
    );
    await tester.pump();

    expect(find.text('Продолжить'), findsOneWidget);
  });

  testWidgets('всё прочитано — «Пройти снова», без CTA', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const DayProgress(
          readTypes: {
            CardType.quote,
            CardType.advice,
            CardType.basics,
            CardType.reading,
          },
          streakDays: 5,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Пройти снова'), findsOneWidget);
    expect(find.text('Начать'), findsNothing);
    expect(find.text('Продолжить'), findsNothing);
  });
}
