import '../../../../core/result/result.dart';
import '../entities/today_cards.dart';
import '../repositories/day_cards_repository.dart';

/// Карточки дня в фиксированном порядке показа (порядок enum [CardType]).
/// UI вызывает usecase, не репозиторий напрямую.
class GetTodayCards {
  const GetTodayCards(this._repository);

  final DayCardsRepository _repository;

  Future<Result<TodayCards>> call(DateTime date) async {
    final result = await _repository.getCardsFor(date);
    return switch (result) {
      Success(value: final today) => Success(
          today.copyWith(
            cards: [...today.cards]
              ..sort((a, b) => a.type.index.compareTo(b.type.index)),
          ),
        ),
      Failure(failure: final f) => Failure(f),
    };
  }
}
