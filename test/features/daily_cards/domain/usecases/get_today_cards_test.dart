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
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async => Success(TodayCards(cards: cards));
}

DayCard _card(CardType type) =>
    DayCard(id: type.name, type: type, body: 'b', source: 's');

void main() {
  test('возвращает карточки строго в порядке '
      'quote → advice → parable → reading → basics', () async {
    // Репозиторий отдаёт вперемешку — usecase обязан отсортировать.
    final repo = _FakeRepository([
      _card(CardType.reading),
      _card(CardType.quote),
      _card(CardType.basics),
      _card(CardType.advice),
      _card(CardType.parable),
    ]);
    final usecase = GetTodayCards(repo);

    final result = await usecase(DateTime(2026, 7, 7));

    expect(result, isA<Success<TodayCards>>());
    final cards = (result as Success<TodayCards>).value.cards;
    // Этот же порядок — очередь автооткрытия при входе в приложение.
    // Первые три составляют сессию дня, дальше идут отдельные треки.
    expect(cards.map((c) => c.type).toList(), [
      CardType.quote,
      CardType.advice,
      CardType.parable,
      CardType.reading,
      CardType.basics,
    ]);
  });
}
