import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/light_day_lamp.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingDayProgress implements DayProgressRepository {
  static const _failure = Failure<DayProgress>(
    AppFailure('Запись отклонена', kind: FailureKind.unknown),
  );

  @override
  Future<Result<DayProgress>> loadToday() async =>
      const Success(DayProgress(readTypes: {}, visitedDays: {}));

  @override
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) async => _failure;

  @override
  Future<Result<DayProgress>> completeWisdom({
    DateTime? date,
    bool markVisited = true,
  }) async => _failure;

  @override
  Future<Result<DayProgress>> markVisited({DateTime? date}) async => _failure;
}

DayLampResult _unwrap(Result<DayLampResult> r) =>
    (r as Success<DayLampResult>).value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 10, 21, 30);
  final yesterday = DateTime(2026, 11, 9);

  Future<PrefsDayProgressRepository> repoWith({
    List<String> visited = const [],
  }) async {
    SharedPreferences.setMockInitialValues({
      if (visited.isNotEmpty)
        'flutter.day_progress': jsonEncode({
          'date': dateKey(now),
          'readTypes': <String>[],
          'visitedDays': visited,
        }),
    });
    return PrefsDayProgressRepository(
      await SharedPreferences.getInstance(),
      clock: () => now,
    );
  }

  test('дочитанный сегодня раздел зажигает лампаду и начинает серию', () async {
    final repo = await repoWith();

    final result = _unwrap(
      await LightDayLamp(repo, clock: () => now)(contentDate: now),
    );

    expect(result.litNow, isTrue);
    expect(result.restarted, isTrue);
    expect(result.progress.isLit(now), isTrue);
    expect(result.progress.streakOn(now), 1);
    expect(result.progress.readTypes, isEmpty);
    expect(
      (await repo.loadToday() as Success<DayProgress>).value.isLit(now),
      isTrue,
    );
  });

  test('вчерашняя активность продолжает серию, а не начинает её', () async {
    final repo = await repoWith(visited: [dateKey(yesterday)]);

    final result = _unwrap(await LightDayLamp(repo, clock: () => now)());

    expect(result.litNow, isTrue);
    expect(result.restarted, isFalse);
    expect(result.progress.streakOn(now), 2);
  });

  test('уже горящая лампада второй раз не зажигается', () async {
    final repo = await repoWith(visited: [dateKey(now)]);

    final result = _unwrap(await LightDayLamp(repo, clock: () => now)());

    expect(result.litNow, isFalse);
    expect(result.progress.isLit(now), isTrue);
  });

  test('раздел прошлого дня лампаду не зажигает', () async {
    // Экран открыт до полуночи, а дочитан после: засчитывать задним числом
    // нельзя, а сегодня юзер этот раздел дня не читал.
    final repo = await repoWith();

    final result = _unwrap(
      await LightDayLamp(repo, clock: () => now)(contentDate: yesterday),
    );

    expect(result.litNow, isFalse);
    expect(result.progress.isLit(now), isFalse);
    expect(result.progress.isLit(yesterday), isFalse);
    final stored = (await repo.loadToday() as Success<DayProgress>).value;
    expect(stored.visitedDays, isEmpty);
  });

  test('сбой записи возвращается как Failure', () async {
    final result = await LightDayLamp(
      _FailingDayProgress(),
      clock: () => now,
    )();

    expect(result, isA<Failure<DayLampResult>>());
  });
}
