import '../dto/day_card_dto.dart';

/// Источник дневного контента. Может бросать исключения —
/// их гасит repository impl.
abstract interface class DayCardsRemoteDatasource {
  Future<List<DayCardDto>> fetchCardsFor(DateTime date);
}

/// Мок до реального парсинга Азбуки веры.
/// TODO: заменить на HTTP-реализацию (дневные фиды Азбуки).
class MockDayCardsRemoteDatasource implements DayCardsRemoteDatasource {
  @override
  Future<List<DayCardDto>> fetchCardsFor(DateTime date) async {
    return const [
      DayCardDto(
        id: 'quote-2026-07-07',
        type: 'quote',
        title: 'Мысль дня',
        body: 'Каково главное дело? Стоять умом в сердце пред Богом '
            'и стоять неотходно день и ночь до конца жизни.',
        source: 'свт. Феофан Затворник',
      ),
      DayCardDto(
        id: 'advice-2026-07-07',
        type: 'advice',
        title: 'Совет дня',
        body: 'Placeholder: практический совет из дневного фида Азбуки.',
        source: 'Азбука веры',
      ),
      DayCardDto(
        id: 'basics-2026-07-07',
        type: 'basics',
        title: 'Основы православия',
        body: 'Placeholder: порция основ веры из дневного фида Азбуки.',
        source: 'Азбука веры',
      ),
      DayCardDto(
        id: 'reading-2026-07-07',
        type: 'reading',
        title: 'Чтение дня',
        body: 'Placeholder: евангельское чтение дня, дозированно.',
        source: 'Азбука веры',
      ),
    ];
  }
}
