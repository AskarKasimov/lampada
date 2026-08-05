import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/network/network_status.dart';
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

class _OfflineNetworkStatus implements NetworkStatus {
  @override
  Future<bool> isOnline() async => false;
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
    // Кэш подневный: ключ включает дату, иначе календарь не смог бы
    // держать больше одного дня.
    expect(prefs.getString('day_cards_cache_v2:2026-07-19'), isNotNull);
    expect(prefs.getStringList('day_cards_cached_dates_v2'), ['2026-07-19']);
  });

  test('кэш держит несколько дней одновременно', () async {
    final prefs = await _emptyPrefs();
    await _repo(_FakeDatasource([_card]), prefs)
        .getCardsFor(DateTime(2026, 7, 19));
    await _repo(_FakeDatasource([_card]), prefs)
        .getCardsFor(DateTime(2026, 7, 20));

    // Раньше один общий ключ помнил ровно последний день, и шаг назад
    // по календарю снова шёл в сеть.
    final result = await _repo(_NeverCalledDatasource(), prefs)
        .getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Success<TodayCards>>());
    expect(prefs.getStringList('day_cards_cached_dates_v2'),
        ['2026-07-19', '2026-07-20']);
  });

  test('индекс кэша отсортирован по дате, а не по порядку записи', () async {
    // По последнему элементу выбирается stale-день: «последний» обязан
    // значить «самый поздний».
    final prefs = await _emptyPrefs();
    await _repo(_FakeDatasource([_card]), prefs)
        .getCardsFor(DateTime(2026, 7, 20));
    await _repo(_FakeDatasource([_card]), prefs)
        .getCardsFor(DateTime(2026, 7, 19));

    expect(prefs.getStringList('day_cards_cached_dates_v2'),
        ['2026-07-19', '2026-07-20']);
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

  test('сеть упала + кэш только за другую дату → Failure', () async {
    final prefs = await _emptyPrefs();
    await _repo(_FakeDatasource([_card]), prefs)
        .getCardsFor(DateTime(2026, 7, 18));

    final result = await _repo(
      _FakeDatasource(const RemoteFetchException(FailureKind.network, 'нет сети')),
      prefs,
    ).getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Failure<TodayCards>>());
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

  test('без сети и кэша день завершается без запроса к источнику', () async {
    final prefs = await _emptyPrefs();
    final remote = _CountingDatasource(
      const RemoteFetchException(FailureKind.unknown, 'не должен зваться'),
    );
    final repo = AzbykaDayCardsRepository(
      remote,
      prefs,
      networkStatus: _OfflineNetworkStatus(),
    );

    final result = await repo.getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Failure<TodayCards>>());
    expect((result as Failure<TodayCards>).failure.kind, FailureKind.network);
    expect(remote.calls, 0, reason: 'в офлайне не ждём ни одной попытки');
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

  test('запись кэша с неизвестным типом карточки — промах, а не сбой', () async {
    // Эта ловушка кусала дважды и оба раза выглядела как «источник недоступен»:
    // маппер разворачивает тип через CardType.values.byName, тот бросает
    // ArgumentError (это Error, не Exception), и разбор падал НА КЭШЕ, не
    // доходя до сети. Так удаление «вопроса дня» дало офлайн-экран при живом
    // интернете.
    SharedPreferences.setMockInitialValues({
      'flutter.day_cards_cache_v2:2026-07-19': jsonEncode([
        {
          'id': 'question-2026-07-19',
          'type': 'question',
          'body': 'body',
          'source': 'source',
        },
      ]),
      'flutter.day_cards_cached_dates_v2': ['2026-07-19'],
    });
    final prefs = await SharedPreferences.getInstance();
    final remote = _FakeDatasource([_card]);

    final result = await _repo(remote, prefs).getCardsFor(DateTime(2026, 7, 19));

    expect(result, isA<Success<TodayCards>>());
    expect((result as Success<TodayCards>).value.cards.single.id,
        'quote-2026-07-19');
  });
}
