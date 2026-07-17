import '../../../../core/result/result.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/repositories/day_cards_repository.dart';
import '../dto/day_card_dto.dart';
import '../mappers/day_card_mapper.dart';

/// Мок-реализация до реального парсинга Азбуки веры.
/// Репозиторий сам отвечает за получение данных (без отдельного datasource);
/// единственное место, где исключения data-слоя превращаются в Failure.
/// TODO: заменить на HTTP-реализацию (дневные фиды Азбуки).
class MockDayCardsRepository implements DayCardsRepository {
  const MockDayCardsRepository();

  @override
  Future<Result<List<DayCard>>> getCardsFor(DateTime date) async {
    try {
      final dtos = await _fetchCardsFor(date);
      return Success(dtos.map((dto) => dto.toEntity()).toList());
    } on Exception catch (e) {
      return Failure(AppFailure('Не удалось загрузить карточки дня', cause: e));
    }
  }

  Future<List<DayCardDto>> _fetchCardsFor(DateTime date) async {
    return const [
      DayCardDto(
        id: 'quote-2026-07-07',
        type: 'quote',
        body: 'Каково главное дело? Стоять умом в сердце пред Богом '
            'и стоять неотходно день и ночь до конца жизни.',
        source: 'свт. Феофан Затворник',
      ),
      DayCardDto(
        id: 'advice-2026-07-07',
        type: 'advice',
        body: 'Сегодня, вставая из-за стола, скажи благодарственную '
            'молитву своими словами — необязательно по книге.',
        source: 'Азбука веры',
      ),
      DayCardDto(
        id: 'basics-2026-07-07',
        type: 'basics',
        body: 'Крестное знамение — не просто жест. Три сложенных перста — '
            'образ Троицы, два прижатых к ладони — образ двух естеств '
            'во Христе.',
        source: 'Азбука веры',
      ),
      DayCardDto(
        id: 'reading-2026-07-07',
        type: 'reading',
        body: 'Ты же, когда молишься, войди в комнату твою и, затворив '
            'дверь твою, помолись Отцу твоему, Который втайне; и Отец '
            'твой, видящий тайное, воздаст тебе явно.',
        source: 'Мф. 6:6',
      ),
    ];
  }
}
