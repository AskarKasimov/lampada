import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

DayProgress _unwrap(Result<DayProgress> r) => (r as Success<DayProgress>).value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime fixedNow = DateTime(2026, 7, 17);

  Future<PrefsDayProgressRepository> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return PrefsDayProgressRepository(prefs, clock: () => fixedNow);
  }

  setUp(() => fixedNow = DateTime(2026, 7, 17));

  test('свежий прогресс: пусто, огонька нет', () async {
    final repo = await build();

    final p = _unwrap(await repo.loadToday());

    expect(p.readTypes, isEmpty);
    expect(p.visitedDays, isEmpty);
    expect(p.streakOn(fixedNow), 0);
  });

  test('markRead добавляет тип и переживает перезагрузку', () async {
    final repo = await build();

    await repo.markRead(CardType.quote);

    expect(_unwrap(await repo.loadToday()).readTypes, {CardType.quote});
  });

  test('первая же карточка засчитывает день посещённым', () async {
    // Отдельного «завершить день» больше нет: по §1 сессия состоялась
    // уже после первой карточки.
    final repo = await build();

    final p = _unwrap(await repo.markRead(CardType.quote));

    expect(p.isLit(fixedNow), isTrue);
    expect(p.streakOn(fixedNow), 1);
  });

  test('повторное чтение в тот же день день не удваивает', () async {
    final repo = await build();

    await repo.markRead(CardType.quote);
    final p = _unwrap(await repo.markRead(CardType.advice));

    expect(p.visitedDays, hasLength(1));
  });

  test(
    'на новый день прочитанное сбрасывается, посещённые дни остаются',
    () async {
      final repo = await build();
      await repo.markRead(CardType.quote);

      fixedNow = DateTime(2026, 7, 18);
      final p = _unwrap(await repo.loadToday());

      expect(p.readTypes, isEmpty);
      expect(p.isLit(DateTime(2026, 7, 17)), isTrue);
    },
  );

  test('хранит прочитанные типы для прошлых дней', () async {
    final repo = await build();
    await repo.markRead(CardType.quote);

    fixedNow = DateTime(2026, 7, 18);
    await repo.markRead(CardType.advice);

    final prefs = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(prefs.getString('day_progress')!) as Map<String, dynamic>;
    expect(stored['readTypesByDate'], {
      '2026-07-17': ['quote'],
      '2026-07-18': ['advice'],
    });
    final progress = _unwrap(await repo.loadToday());
    expect(progress.isReadOn(DateTime(2026, 7, 17), CardType.quote), isTrue);
  });

  test('прочтение прошлого дня не засчитывает посещение', () async {
    final repo = await build();
    final yesterday = DateTime(2026, 7, 16);

    final progress = _unwrap(
      await repo.markRead(CardType.quote, date: yesterday, markVisited: false),
    );

    expect(progress.isReadOn(yesterday, CardType.quote), isTrue);
    expect(progress.isLit(yesterday), isFalse);
  });

  test('completeWisdom отмечает завершение и зажигает день', () async {
    final repo = await build();

    final p = _unwrap(await repo.completeWisdom());

    expect(p.isWisdomCompletedOn(fixedNow), isTrue);
    expect(p.isLit(fixedNow), isTrue);
    expect(p.streakOn(fixedNow), 1);
    expect(p.readTypes, isEmpty);
    expect(p.readTypesByDate, isEmpty);
    final reloaded = _unwrap(await repo.loadToday());
    expect(reloaded.isWisdomCompletedOn(fixedNow), isTrue);
    expect(reloaded.isLit(fixedNow), isTrue);
  });

  test('завершение прошлого дня не зажигает его', () async {
    final repo = await build();
    final yesterday = DateTime(2026, 7, 16);

    final p = _unwrap(
      await repo.completeWisdom(date: yesterday, markVisited: false),
    );

    expect(p.isWisdomCompletedOn(yesterday), isTrue);
    expect(p.isWisdomCompletedOn(fixedNow), isFalse);
    expect(p.isLit(yesterday), isFalse);
  });

  test('completeWisdom не теряет прочитанное за день', () async {
    final repo = await build();
    await repo.markRead(CardType.quote, markVisited: false);

    final p = _unwrap(await repo.completeWisdom());

    expect(p.readTypes, {CardType.quote});
    expect(p.visitedDays, {'2026-07-17'});
  });

  test('переносит прочитанные типы из прежнего формата', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.day_progress': jsonEncode({
        'date': '2026-07-16',
        'readTypes': ['quote'],
        'visitedDays': ['2026-07-16'],
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsDayProgressRepository(prefs, clock: () => fixedNow);

    await repo.markRead(CardType.advice);

    final stored =
        jsonDecode(prefs.getString('day_progress')!) as Map<String, dynamic>;
    expect(stored['readTypesByDate'], {
      '2026-07-16': ['quote'],
      '2026-07-17': ['advice'],
    });
    final progress = _unwrap(await repo.loadToday());
    expect(progress.isReadOn(DateTime(2026, 7, 16), CardType.quote), isTrue);
  });

  test('серия растёт по дням, а не по прочитанным карточкам', () async {
    final repo = await build();
    await repo.markRead(CardType.quote);
    fixedNow = DateTime(2026, 7, 18);
    await repo.markRead(CardType.quote);
    fixedNow = DateTime(2026, 7, 19);
    await repo.markRead(CardType.quote);

    expect(_unwrap(await repo.loadToday()).streakOn(fixedNow), 3);
  });

  test('возврат после долгого перерыва не продолжает старую серию', () async {
    final repo = await build();
    await repo.markRead(CardType.quote);

    fixedNow = DateTime(2026, 8, 17);
    final p = _unwrap(await repo.markRead(CardType.quote));

    expect(p.streakOn(fixedNow), 1);
  });

  test('прогресс переживает пересоздание репозитория (те же prefs)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = PrefsDayProgressRepository(prefs, clock: () => fixedNow);
    await first.markRead(CardType.quote);

    final second = PrefsDayProgressRepository(prefs, clock: () => fixedNow);
    final p = _unwrap(await second.loadToday());

    expect(p.readTypes, {CardType.quote});
    expect(p.isLit(fixedNow), isTrue);
  });

  test('прогресс с неизвестным типом карточки читается, а не падает', () async {
    // Прогресс — данные юзера, их нельзя терять из-за неизвестного типа.
    // Раньше CardType.values.byName бросал тут ArgumentError (Error, не
    // Exception), и экран «Сегодня» уходил в офлайн при живом интернете и
    // уже загруженных карточках.
    SharedPreferences.setMockInitialValues({
      'flutter.day_progress': jsonEncode({
        'date': dateKey(DateTime.now()),
        'readTypes': ['quote', 'legacy', 'advice'],
        'visitedDays': <String>[],
      }),
    });
    final prefs = await SharedPreferences.getInstance();

    final result = await PrefsDayProgressRepository(prefs).loadToday();

    expect(result, isA<Success<DayProgress>>());
    final progress = (result as Success<DayProgress>).value;
    expect(progress.readTypes, {CardType.quote, CardType.advice});
  });

  test('прогресс с убранным «вопросом дня» не теряет остальное', () async {
    // Не выдуманный `legacy`, а тип, который прямо сейчас лежит в prefs у всех,
    // кто открывал приложение до замены вопроса на притчу.
    SharedPreferences.setMockInitialValues({
      'flutter.day_progress': jsonEncode({
        'date': dateKey(DateTime.now()),
        'readTypes': ['quote', 'question'],
        'visitedDays': <String>[],
      }),
    });
    final prefs = await SharedPreferences.getInstance();

    final result = await PrefsDayProgressRepository(prefs).loadToday();

    expect(result, isA<Success<DayProgress>>());
    final progress = (result as Success<DayProgress>).value;
    expect(progress.readTypes, {CardType.quote});
  });

  group('время прочтения «Мудрости дня»', () {
    // От него отсчитываются дневные напоминания о святом и курсе; расписание
    // пересобирается часто, поэтому момент нужно хранить, а не брать «сейчас».
    test('первое завершение сегодня запоминает момент', () async {
      fixedNow = DateTime(2026, 7, 17, 10, 30);
      final repo = await build();

      final p = _unwrap(await repo.completeWisdom());

      expect(p.wisdomCompletedAt, DateTime(2026, 7, 17, 10, 30));
    });

    test('повторное завершение не сдвигает момент', () async {
      fixedNow = DateTime(2026, 7, 17, 10, 30);
      final repo = await build();
      await repo.completeWisdom();

      fixedNow = DateTime(2026, 7, 17, 15);
      final p = _unwrap(await repo.completeWisdom());

      expect(p.wisdomCompletedAt, DateTime(2026, 7, 17, 10, 30));
    });

    test('завершение другого дня момент не ставит', () async {
      fixedNow = DateTime(2026, 7, 17, 10, 30);
      final repo = await build();

      final p = _unwrap(await repo.completeWisdom(date: DateTime(2026, 7, 16)));

      expect(p.wisdomCompletedAt, isNull);
    });

    test('назавтра вчерашний момент не считается сегодняшним', () async {
      fixedNow = DateTime(2026, 7, 17, 10, 30);
      final repo = await build();
      await repo.completeWisdom();

      fixedNow = DateTime(2026, 7, 18, 8);
      final p = _unwrap(await repo.loadToday());

      expect(p.wisdomCompletedAt, isNull);
    });
  });
}
