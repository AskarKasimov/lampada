import 'package:lampada/core/format/date_key.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

DayProgress _unwrap(Result<DayProgress> r) =>
    (r as Success<DayProgress>).value;

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

  test('на новый день прочитанное сбрасывается, посещённые дни остаются',
      () async {
    final repo = await build();
    await repo.markRead(CardType.quote);

    fixedNow = DateTime(2026, 7, 18);
    final p = _unwrap(await repo.loadToday());

    expect(p.readTypes, isEmpty);
    expect(p.isLit(DateTime(2026, 7, 17)), isTrue);
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

  test('сохранённый вопрос дня остаётся прочитанным', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.day_progress': jsonEncode({
        'date': dateKey(DateTime.now()),
        'readTypes': ['question'],
        'visitedDays': <String>[],
      }),
    });
    final prefs = await SharedPreferences.getInstance();

    final result = await PrefsDayProgressRepository(prefs).loadToday();

    expect(result, isA<Success<DayProgress>>());
    final progress = (result as Success<DayProgress>).value;
    expect(progress.readTypes, {CardType.question});
  });
}
