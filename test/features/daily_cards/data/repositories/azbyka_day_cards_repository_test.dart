import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/datasources/day_cards_remote_datasource.dart';
import 'package:lampada/features/daily_cards/data/dto/day_card_dto.dart';
import 'package:lampada/features/daily_cards/data/repositories/azbyka_day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDatasource implements DayCardsRemoteDatasource {
  _FakeDatasource(this._result);
  final Object _result; // List<DayCardDto> или Exception

  @override
  Future<List<DayCardDto>> fetch(DateTime date) async {
    if (_result is Exception) throw _result;
    return _result as List<DayCardDto>;
  }
}

class _NeverCalledDatasource implements DayCardsRemoteDatasource {
  @override
  Future<List<DayCardDto>> fetch(DateTime date) async {
    throw StateError('fetch не должен зваться, если кэш свежий');
  }
}

const _card = DayCardDto(
  id: 'quote-2026-07-19',
  type: 'quote',
  body: 'body',
  source: 'source',
);

Future<SharedPreferences> _emptyPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('успешный скрейп возвращает карточки и пишет кэш', () async {
    final prefs = await _emptyPrefs();
    final repo = AzbykaDayCardsRepository(
      _FakeDatasource([_card]),
      prefs,
    );

    final result = await repo.getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Success<List<DayCard>>>());
    final cards = (result as Success<List<DayCard>>).value;
    expect(cards.single.id, 'quote-2026-07-19');
    expect(prefs.getString('day_cards_cache'), isNotNull);
  });

  test('кэш есть за запрошенную дату → сеть не дёргаем', () async {
    final prefs = await _emptyPrefs();
    final warmup = AzbykaDayCardsRepository(_FakeDatasource([_card]), prefs);
    await warmup.getCardsFor(DateTime(2026, 7, 19));

    final repo = AzbykaDayCardsRepository(_NeverCalledDatasource(), prefs);
    final result = await repo.getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Success<List<DayCard>>>());
    final cards = (result as Success<List<DayCard>>).value;
    expect(cards.single.id, 'quote-2026-07-19');
  });

  test('ошибка сети + есть кэш → отдаёт кэш', () async {
    final prefs = await _emptyPrefs();
    // Прогреваем кэш успешным запросом через первый инстанс репозитория.
    final warmup = AzbykaDayCardsRepository(_FakeDatasource([_card]), prefs);
    await warmup.getCardsFor(DateTime(2026, 7, 18));

    final failing = AzbykaDayCardsRepository(
      _FakeDatasource(Exception('нет сети')),
      prefs,
    );
    final result = await failing.getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Success<List<DayCard>>>());
    final cards = (result as Success<List<DayCard>>).value;
    expect(cards.single.id, 'quote-2026-07-19');
  });

  test('ошибка сети + кэша нет → Failure', () async {
    final prefs = await _emptyPrefs();
    final repo = AzbykaDayCardsRepository(
      _FakeDatasource(Exception('нет сети')),
      prefs,
    );

    final result = await repo.getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Failure<List<DayCard>>>());
  });
}
