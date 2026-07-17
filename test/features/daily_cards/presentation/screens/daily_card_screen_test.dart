import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/daily_card_screen.dart';

class _FakeRepository implements DayCardsRepository {
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

void main() {
  Widget buildApp() => ProviderScope(
        overrides: [
          dayCardsRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: DailyCardScreen()),
      );

  testWidgets('проходит все карточки дня и доходит до экрана завершения',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
    // никогда не осядет. Прокачиваем ровно на длительность анимации карточки.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Первая карточка'), findsOneWidget);
    expect(find.text('Дальше'), findsOneWidget);

    await tester.tap(find.text('Дальше'));
    await tester.pump();
    // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
    // никогда не осядет. Прокачиваем ровно на длительность анимации карточки.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Последняя карточка'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);

    await tester.tap(find.text('Готово'));
    await tester.pump();
    // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
    // никогда не осядет. Прокачиваем ровно на длительность анимации карточки.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Мысль дня получена'), findsOneWidget);
    expect(find.text('Пройти сначала'), findsOneWidget);
  });

  testWidgets('«Пройти сначала» возвращает к первой карточке', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
    // никогда не осядет. Прокачиваем ровно на длительность анимации карточки.
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Дальше'));
    await tester.pump();
    // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
    // никогда не осядет. Прокачиваем ровно на длительность анимации карточки.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Готово'));
    await tester.pump();
    // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
    // никогда не осядет. Прокачиваем ровно на длительность анимации карточки.
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Пройти сначала'));
    await tester.pump();
    // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
    // никогда не осядет. Прокачиваем ровно на длительность анимации карточки.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Первая карточка'), findsOneWidget);
    expect(find.text('Дальше'), findsOneWidget);
  });
}
