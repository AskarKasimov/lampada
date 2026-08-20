import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/network/network_status.dart';
import 'package:lampada/core/network/remote_fetch_exception.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/day_story/data/datasources/day_story_remote_datasource.dart';
import 'package:lampada/features/day_story/data/dto/day_story_dto.dart';
import 'package:lampada/features/day_story/data/repositories/azbyka_day_story_repository.dart';
import 'package:lampada/features/day_story/domain/entities/day_story.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _url = 'https://azbyka.ru/days/sv-ivanov';

class _FakeDatasource implements DayStoryRemoteDatasource {
  int calls = 0;

  @override
  Future<DayStoryDto> fetch(String url, {required Duration timeout}) async {
    calls++;
    return const DayStoryDto(paragraphs: ['СВЕЖИЙ РАССКАЗ']);
  }
}

class _FailingDatasource implements DayStoryRemoteDatasource {
  _FailingDatasource(this.kind);

  final FailureKind kind;
  int calls = 0;

  @override
  Future<DayStoryDto> fetch(String url, {required Duration timeout}) async {
    calls++;
    throw RemoteFetchException(kind, 'сбой');
  }
}

class _OfflineNetworkStatus implements NetworkStatus {
  @override
  Future<bool> isOnline() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  DayStory valueOf(Result<DayStory> result) =>
      (result as Success<DayStory>).value;

  test('кэш отдаётся без похода в сеть', () async {
    final prefs = await prefsWith({});
    final remote = _FakeDatasource();
    final repo = AzbykaDayStoryRepository(remote, prefs);

    await repo.fetch(_url);
    final second = await repo.fetch(_url);

    expect(remote.calls, 1, reason: 'второй раз полезли в сеть');
    expect(valueOf(second).paragraphs, ['СВЕЖИЙ РАССКАЗ']);
  });

  test('битый кэш не роняет рассказ — молча идём в сеть', () async {
    final prefs = await prefsWith({'day_story_cache_v2:$_url': 'не json'});
    final remote = _FakeDatasource();

    final result = await AzbykaDayStoryRepository(remote, prefs).fetch(_url);

    expect(remote.calls, 1);
    expect(valueOf(result).paragraphs, ['СВЕЖИЙ РАССКАЗ']);
  });

  test('кэш верного JSON-типа не роняет рассказ — молча идём в сеть', () async {
    final prefs = await prefsWith({'day_story_cache_v2:$_url': '"не объект"'});
    final remote = _FakeDatasource();

    final result = await AzbykaDayStoryRepository(remote, prefs).fetch(_url);

    expect(remote.calls, 1);
    expect(valueOf(result).paragraphs, ['СВЕЖИЙ РАССКАЗ']);
  });

  test('без сети и кэша — сразу отказ без похода к источнику', () async {
    final prefs = await prefsWith({});
    final remote = _FakeDatasource();
    final repo = AzbykaDayStoryRepository(
      remote,
      prefs,
      networkStatus: _OfflineNetworkStatus(),
    );

    final result = await repo.fetch(_url);

    expect(result, isA<Failure<DayStory>>());
    expect((result as Failure<DayStory>).failure.kind, FailureKind.network);
    expect(remote.calls, 0, reason: 'в офлайне не ждём загрузку рассказа');
  });

  test(
    'вёрстка страницы не разобралась (unknown) — без повторных попыток',
    () async {
      final prefs = await prefsWith({});
      final remote = _FailingDatasource(FailureKind.unknown);

      final result = await AzbykaDayStoryRepository(
        remote,
        prefs,
        retryDelays: const [Duration(milliseconds: 1)],
      ).fetch(_url);

      expect(result, isA<Failure<DayStory>>());
      expect(remote.calls, 1, reason: 'повтор той же вёрстки даст тот же сбой');
    },
  );

  test('сетевой сбой повторяется по расписанию', () async {
    final prefs = await prefsWith({});
    final remote = _FailingDatasource(FailureKind.network);

    final result = await AzbykaDayStoryRepository(
      remote,
      prefs,
      retryDelays: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
    ).fetch(_url);

    expect(result, isA<Failure<DayStory>>());
    expect(remote.calls, 3, reason: 'исходная попытка плюс два повтора');
  });

  test('повтор не выходит за общий бюджет рассказа', () async {
    final prefs = await prefsWith({});
    final remote = _DelayedFailingDatasource(const Duration(milliseconds: 600));
    final stopwatch = Stopwatch()..start();

    await AzbykaDayStoryRepository(
      remote,
      prefs,
      budget: const Duration(milliseconds: 700),
      retryDelays: const [Duration(seconds: 1)],
    ).fetch(_url);

    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 850)));
    expect(remote.calls, 1, reason: 'на вторую попытку не осталось времени');
  });

  test('успех после повтора попадает в кэш', () async {
    final prefs = await prefsWith({});
    var attempt = 0;
    final remote = _RecoveringDatasource(() {
      attempt++;
      if (attempt == 1) {
        throw const RemoteFetchException(FailureKind.network, 'сбой');
      }
      return const DayStoryDto(paragraphs: ['РАССКАЗ СО ВТОРОЙ ПОПЫТКИ']);
    });

    final result = await AzbykaDayStoryRepository(
      remote,
      prefs,
      retryDelays: const [Duration(milliseconds: 1)],
    ).fetch(_url);

    expect(valueOf(result).paragraphs, ['РАССКАЗ СО ВТОРОЙ ПОПЫТКИ']);
    expect(prefs.getString('day_story_cache_v2:$_url'), isNotNull);
  });

  test('кэш рассказов хранит не больше двадцати URL', () async {
    final prefs = await prefsWith({});
    final remote = _FakeDatasource();
    final repo = AzbykaDayStoryRepository(remote, prefs);
    final urls = List.generate(
      21,
      (index) => 'https://azbyka.ru/days/saint-$index',
    );

    for (final url in urls) {
      await repo.fetch(url);
    }

    final cacheKeys = prefs.getKeys().where(
      (key) => key.startsWith('day_story_cache_v2:'),
    );
    expect(cacheKeys, hasLength(20));

    final refetchRemote = _FakeDatasource();
    await AzbykaDayStoryRepository(refetchRemote, prefs).fetch(urls.first);
    expect(
      refetchRemote.calls,
      1,
      reason: 'самый старый рассказ должен выпасть',
    );
  });

  test('при переходе на v2 удаляется неограниченный кэш v1', () async {
    final legacyCache = <String, Object>{
      for (var index = 0; index < 21; index++)
        'day_story_cache_v1:https://azbyka.ru/days/saint-$index':
            '{"paragraphs":["СТАРЫЙ РАССКАЗ"]}',
    };
    final prefs = await prefsWith(legacyCache);

    await AzbykaDayStoryRepository(_FakeDatasource(), prefs).fetch(_url);

    expect(
      prefs.getKeys().where((key) => key.startsWith('day_story_cache_v1:')),
      isEmpty,
    );
  });
}

class _RecoveringDatasource implements DayStoryRemoteDatasource {
  _RecoveringDatasource(this._behavior);

  final DayStoryDto Function() _behavior;

  @override
  Future<DayStoryDto> fetch(String url, {required Duration timeout}) async =>
      _behavior();
}

class _DelayedFailingDatasource implements DayStoryRemoteDatasource {
  _DelayedFailingDatasource(this.delay);

  final Duration delay;
  var calls = 0;

  @override
  Future<DayStoryDto> fetch(String url, {required Duration timeout}) async {
    calls++;
    await Future<void>.delayed(delay);
    throw const RemoteFetchException(FailureKind.network, 'сбой');
  }
}
