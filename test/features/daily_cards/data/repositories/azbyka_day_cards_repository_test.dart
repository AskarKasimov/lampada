import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/datasources/day_cards_remote_datasource.dart';
import 'package:lampada/features/daily_cards/data/dto/day_card_dto.dart';
import 'package:lampada/features/daily_cards/data/repositories/azbyka_day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDatasource implements DayCardsRemoteDatasource {
  _FakeDatasource(this._result);
  final Object _result; // List<DayCardDto> или Exception

  @override
  Future<List<DayCardDto>> fetch(
    DateTime date, {
    required Duration timeout,
  }) async {
    if (_result is Exception) throw _result;
    return _result as List<DayCardDto>;
  }
}

class _NeverCalledDatasource implements DayCardsRemoteDatasource {
  @override
  Future<List<DayCardDto>> fetch(
    DateTime date, {
    required Duration timeout,
  }) async {
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

/// Репозиторий без пауз между попытками — тесты не должны спать.
AzbykaDayCardsRepository _repo(
  DayCardsRemoteDatasource remote,
  SharedPreferences prefs,
) =>
    AzbykaDayCardsRepository(remote, prefs, retryDelays: const []);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('успешный скрейп возвращает свежие карточки и пишет кэш', () async {
    final prefs = await _emptyPrefs();
    final repo = _repo(_FakeDatasource([_card]), prefs);

    final result = await repo.getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Success<TodayCards>>());
    final today = (result as Success<TodayCards>).value;
    expect(today.cards.single.id, 'quote-2026-07-19');
    expect(today.staleDate, isNull);
    expect(prefs.getString('day_cards_cache'), isNotNull);
  });

  test('кэш есть за запрошенную дату → сеть не дёргаем', () async {
    final prefs = await _emptyPrefs();
    await _repo(_FakeDatasource([_card]), prefs)
        .getCardsFor(DateTime(2026, 7, 19));

    final result =
        await _repo(_NeverCalledDatasource(), prefs)
            .getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Success<TodayCards>>());
    final today = (result as Success<TodayCards>).value;
    expect(today.cards.single.id, 'quote-2026-07-19');
    expect(today.staleDate, isNull);
  });

  test('сеть упала + кэш за другую дату → Success со staleDate', () async {
    final prefs = await _emptyPrefs();
    await _repo(_FakeDatasource([_card]), prefs)
        .getCardsFor(DateTime(2026, 7, 18));

    final result = await _repo(
      _FakeDatasource(const RemoteFetchException(FailureKind.network, 'нет сети')),
      prefs,
    ).getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Success<TodayCards>>());
    final today = (result as Success<TodayCards>).value;
    expect(today.cards.single.id, 'quote-2026-07-19');
    expect(today.staleDate, DateTime(2026, 7, 18));
  });

  test('сеть упала + кэша нет → Failure с kind network', () async {
    final prefs = await _emptyPrefs();

    final result = await _repo(
      _FakeDatasource(const RemoteFetchException(FailureKind.network, 'нет сети')),
      prefs,
    ).getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Failure<TodayCards>>());
    expect((result as Failure<TodayCards>).failure.kind, FailureKind.network);
  });

  test('битая разметка + кэша нет → Failure с kind unknown', () async {
    final prefs = await _emptyPrefs();

    final result = await _repo(
      _FakeDatasource(const RemoteFetchException(FailureKind.unknown, 'вёрстка')),
      prefs,
    ).getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Failure<TodayCards>>());
    expect((result as Failure<TodayCards>).failure.kind, FailureKind.unknown);
  });
}
