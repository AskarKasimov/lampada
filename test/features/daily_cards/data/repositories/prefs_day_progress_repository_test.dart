// test/features/daily_cards/data/repositories/prefs_day_progress_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_day_progress_repository.dart';
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

  test('свежий прогресс: пусто, серия 0', () async {
    final repo = await build();
    final p = _unwrap(await repo.loadToday());
    expect(p.readTypes, isEmpty);
    expect(p.streakDays, 0);
  });

  test('markRead добавляет тип и переживает перезагрузку', () async {
    final repo = await build();
    await repo.markRead(CardType.quote);
    final p = _unwrap(await repo.loadToday());
    expect(p.readTypes, {CardType.quote});
  });

  test('на новый день прочитанное сбрасывается, серия остаётся', () async {
    fixedNow = DateTime(2026, 7, 17);
    final repo = await build();
    await repo.markRead(CardType.quote);
    await repo.completeDay();
    fixedNow = DateTime(2026, 7, 18);
    final p = _unwrap(await repo.loadToday());
    expect(p.readTypes, isEmpty);
    expect(p.streakDays, 1);
  });

  test('completeDay поднимает серию только раз в сутки', () async {
    final repo = await build();
    await repo.completeDay();
    final p = _unwrap(await repo.completeDay());
    expect(p.streakDays, 1);
  });

  test('resetToday чистит прочитанное и откатывает серию за сегодня', () async {
    final repo = await build();
    await repo.markRead(CardType.quote);
    await repo.completeDay();
    final p = _unwrap(await repo.resetToday());
    expect(p.readTypes, isEmpty);
    expect(p.streakDays, 0);
  });
}
