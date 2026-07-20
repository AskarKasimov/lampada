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

/// Считает попытки и запоминает выданные таймауты.
class _CountingDatasource implements DayCardsRemoteDatasource {
  _CountingDatasource(this._error);
  final Exception _error;

  int calls = 0;
  final List<Duration> timeouts = [];

  @override
  Future<List<DayCardDto>> fetch(
    DateTime date, {
    required Duration timeout,
  }) async {
    calls++;
    timeouts.add(timeout);
    throw _error;
  }
}

/// Съедает весь выданный таймаут и падает — так ведёт себя живая, но не
/// отвечающая сеть (captive portal). Нужен, чтобы бюджет реально тратился.
class _SlowDatasource implements DayCardsRemoteDatasource {
  final List<Duration> timeouts = [];

  @override
  Future<List<DayCardDto>> fetch(
    DateTime date, {
    required Duration timeout,
  }) async {
    timeouts.add(timeout);
    await Future<void>.delayed(timeout);
    throw const RemoteFetchException(FailureKind.network, 'таймаут');
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
    AzbykaDayCardsRepository(
      remote,
      prefs,
      retryDelays: const [Duration.zero, Duration.zero],
    );

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

  test('сетевая ошибка ретраится — три попытки', () async {
    final prefs = await _emptyPrefs();
    final remote = _CountingDatasource(
      const RemoteFetchException(FailureKind.network, 'нет сети'),
    );

    await _repo(remote, prefs).getCardsFor(DateTime(2026, 7, 19));

    expect(remote.calls, 3);
  });

  test('битая разметка не ретраится — одна попытка', () async {
    final prefs = await _emptyPrefs();
    final remote = _CountingDatasource(
      const RemoteFetchException(FailureKind.unknown, 'вёрстка'),
    );

    await _repo(remote, prefs).getCardsFor(DateTime(2026, 7, 19));

    expect(remote.calls, 1);
  });

  test('бюджет режет таймаут и обрывает цикл раньше retryDelays', () async {
    final prefs = await _emptyPrefs();
    // Фейк «висящей» сети: съедает весь выданный таймаут, потом падает.
    // Мгновенно падающий фейк бюджет не расходует и клампинг не проверил бы.
    final remote = _SlowDatasource();
    final repo = AzbykaDayCardsRepository(
      remote,
      prefs,
      budget: const Duration(milliseconds: 1500),
      attemptTimeout: const Duration(milliseconds: 900),
      retryDelays: const [Duration.zero, Duration.zero],
    );

    await repo.getCardsFor(DateTime(2026, 7, 19));

    // retryDelays разрешают 3 попытки, бюджета хватило на 2.
    expect(remote.timeouts, hasLength(2));
    expect(remote.timeouts.first, const Duration(milliseconds: 900));
    // Второй достался остаток бюджета, а не полный attemptTimeout.
    expect(remote.timeouts.last, lessThan(const Duration(milliseconds: 900)));
  });
}
