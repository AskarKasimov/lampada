import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/get_today_cards.dart';

class _FakeRepository implements DayCardsRepository {
  _FakeRepository(this.cards);
  final List<DayCard> cards;

  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async =>
      Success(TodayCards(cards: cards));
}

DayCard _card(CardType type) => DayCard(
      id: type.name,
      type: type,
      body: 'b',
      source: 's',
    );

void main() {
  test(
      'возвращает карточки строго в порядке '
      'quote → advice → basics → reading → question', () async {
    // Репозиторий отдаёт вперемешку — usecase обязан отсортировать.
    final repo = _FakeRepository([
      _card(CardType.reading),
      _card(CardType.quote),
      _card(CardType.basics),
      _card(CardType.advice),
      _card(CardType.question),
    ]);
    final usecase = GetTodayCards(repo);

    final result = await usecase(DateTime(2026, 7, 7));

    expect(result, isA<Success<TodayCards>>());
    final cards = (result as Success<TodayCards>).value.cards;
    expect(cards.map((c) => c.type).toList(), [
      CardType.quote,
      CardType.advice,
      CardType.basics,
      CardType.reading,
      CardType.question,
    ]);
  });
}
