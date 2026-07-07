import '../../../../core/result/result.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../datasources/day_cards_remote_datasource.dart';
import '../mappers/day_card_mapper.dart';

/// Единственное место, где исключения data-слоя превращаются в Failure.
class DayCardsRepositoryImpl implements DayCardsRepository {
  const DayCardsRepositoryImpl(this._datasource);

  final DayCardsRemoteDatasource _datasource;

  @override
  Future<Result<List<DayCard>>> getCardsFor(DateTime date) async {
    try {
      final dtos = await _datasource.fetchCardsFor(date);
      return Success(dtos.map((dto) => dto.toEntity()).toList());
    } on Exception catch (e) {
      return Failure(AppFailure('Не удалось загрузить карточки дня', cause: e));
    }
  }
}
