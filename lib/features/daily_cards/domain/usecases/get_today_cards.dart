import '../../../../core/result/result.dart';
import '../entities/day_card.dart';
import '../repositories/day_cards_repository.dart';

/// Карточки дня в фиксированном порядке показа (порядок enum [CardType]).
/// UI вызывает usecase, не репозиторий напрямую.
class GetTodayCards {
  const GetTodayCards(this._repository);

  final DayCardsRepository _repository;

  Future<Result<List<DayCard>>> call(DateTime date) async {
    final result = await _repository.getCardsFor(date);
    return switch (result) {
      Success(value: final cards) => Success(
          [...cards]..sort((a, b) => a.type.index.compareTo(b.type.index)),
        ),
      Failure(failure: final f) => Failure(f),
    };
  }
}
