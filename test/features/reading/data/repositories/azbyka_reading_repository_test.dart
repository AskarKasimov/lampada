import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/network/network_status.dart';
import 'package:lampada/core/network/remote_fetch_exception.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/reading/data/datasources/reading_remote_datasource.dart';
import 'package:lampada/features/reading/data/dto/daily_reading_dto.dart';
import 'package:lampada/features/reading/data/repositories/azbyka_reading_repository.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _reference = 'Jn.10:1-9';

/// Кэш прошлой схемы: у стихов нет полей толкования, зато есть верхнеуровневое
/// `interpretation` — так выглядела запись, когда толкование было одно на весь
/// отрывок.
final _legacyCache = jsonEncode({
  'label': 'Ин.10:1–9',
  'verses': [
    {'number': 1, 'chapter': 10, 'text': 'СТИХ ИЗ СТАРОГО КЭША'},
  ],
  'interpretation': 'ТОЛКОВАНИЕ НА ВЕСЬ ОТРЫВОК',
  'interpretationAuthor': 'Феофилакт Болгарский, блж.',
});

class _FakeDatasource implements ReadingRemoteDatasource {
  int calls = 0;

  @override
  Future<DailyReadingDto> fetch(
    String reference, {
    required Duration timeout,
  }) async {
    calls++;
    return const DailyReadingDto(
      label: 'Ин.10:1–9',
      verses: [
        VerseDto(
          number: 1,
          chapter: 10,
          text: 'СВЕЖИЙ СТИХ',
          interpretation: 'СВЕЖЕЕ ТОЛКОВАНИЕ',
          interpretationRange: 'Ин.10:1',
        ),
      ],
      interpretationAuthor: 'Феофилакт Болгарский, блж.',
    );
  }
}

class _FailingDatasource implements ReadingRemoteDatasource {
  @override
  Future<DailyReadingDto> fetch(
    String reference, {
    required Duration timeout,
  }) async => throw const RemoteFetchException(FailureKind.unknown, 'нет сети');
}

class _OfflineNetworkStatus implements NetworkStatus {
  @override
  Future<bool> isOnline() async => false;
}

class _FailingCacheStore extends SharedPreferencesStorePlatform {
  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() async => {};

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      Future<bool>.error(Exception('диск недоступен'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  DailyReading valueOf(Result<DailyReading> result) =>
      (result as Success<DailyReading>).value;

  test('кэш прошлой схемы не используется — идём в сеть', () async {
    // Поля толкования у стиха необязательные, поэтому старая запись
    // разбиралась БЕЗ ошибки и отдавала чтение вовсе без толкований:
    // в ридере не оставалось ничего, что можно тапнуть.
    final prefs = await prefsWith({'reading_cache:$_reference': _legacyCache});
    final remote = _FakeDatasource();

    final result = await AzbykaReadingRepository(
      remote,
      prefs,
    ).getReading(_reference);

    expect(remote.calls, 1, reason: 'старый кэш приняли за свежий');
    final reading = valueOf(result);
    expect(reading.verses.single.text, 'СВЕЖИЙ СТИХ');
    expect(reading.verses.single.interpretation, 'СВЕЖЕЕ ТОЛКОВАНИЕ');
  });

  test('кэш прошлой схемы не подменяет ошибку загрузки', () async {
    // Иначе сбой сети «вылечился» бы записью без толкований.
    final prefs = await prefsWith({'reading_cache:$_reference': _legacyCache});

    final result = await AzbykaReadingRepository(
      _FailingDatasource(),
      prefs,
      retryDelays: const [],
    ).getReading(_reference);

    expect(result, isA<Failure<DailyReading>>());
  });

  test('кэш текущей схемы отдаётся без похода в сеть', () async {
    final prefs = await prefsWith({});
    final remote = _FakeDatasource();
    final repo = AzbykaReadingRepository(remote, prefs);

    await repo.getReading(_reference);
    final second = await repo.getReading(_reference);

    expect(remote.calls, 1, reason: 'второй раз полезли в сеть');
    expect(valueOf(second).verses.single.interpretation, 'СВЕЖЕЕ ТОЛКОВАНИЕ');
  });

  test('свежее чтение возвращается при ошибке записи кэша', () async {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = _FailingCacheStore();
    final prefs = await SharedPreferences.getInstance();
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    final result = await AzbykaReadingRepository(
      _FakeDatasource(),
      prefs,
    ).getReading(_reference);

    expect(result, isA<Success<DailyReading>>());
  });

  test('без сети и кэша чтение завершается без запроса к источнику', () async {
    final prefs = await prefsWith({});
    final remote = _FakeDatasource();
    final repo = AzbykaReadingRepository(
      remote,
      prefs,
      networkStatus: _OfflineNetworkStatus(),
    );

    final result = await repo.getReading(_reference);

    expect(result, isA<Failure<DailyReading>>());
    expect((result as Failure<DailyReading>).failure.kind, FailureKind.network);
    expect(remote.calls, 0, reason: 'в офлайне не ждём загрузку чтения');
  });

  test('битый кэш не роняет чтение — молча идём в сеть', () async {
    final prefs = await prefsWith({'reading_cache_v2:$_reference': 'не json'});
    final remote = _FakeDatasource();

    final result = await AzbykaReadingRepository(
      remote,
      prefs,
    ).getReading(_reference);

    expect(remote.calls, 1);
    expect(valueOf(result).verses.single.text, 'СВЕЖИЙ СТИХ');
  });
}
