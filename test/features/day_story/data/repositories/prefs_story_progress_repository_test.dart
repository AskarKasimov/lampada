import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/day_story/data/repositories/prefs_story_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Set<String> _unwrap(Result<Set<String>> r) => (r as Success<Set<String>>).value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  test('свежая установка: ни одного прочитанного рассказа', () async {
    final repo = PrefsStoryProgressRepository(await prefs());

    expect(_unwrap(await repo.readDays()), isEmpty);
  });

  test('отметка дня переживает пересоздание репозитория', () async {
    // Напоминание о святом не должно приходить тому, кто уже прочитал.
    final store = await prefs();
    await PrefsStoryProgressRepository(store).markRead(DateTime(2026, 7, 17));

    final days = _unwrap(await PrefsStoryProgressRepository(store).readDays());

    expect(days, {'2026-07-17'});
  });

  test('повторная отметка того же дня не дублирует его', () async {
    final repo = PrefsStoryProgressRepository(await prefs());

    await repo.markRead(DateTime(2026, 7, 17, 9));
    final days = _unwrap(await repo.markRead(DateTime(2026, 7, 17, 20)));

    expect(days, {'2026-07-17'});
  });

  test('история ограничена, prefs не растут вечно', () async {
    final repo = PrefsStoryProgressRepository(await prefs());
    final start = DateTime(2024);

    for (var i = 0; i < 405; i++) {
      await repo.markRead(start.add(Duration(days: i)));
    }
    final days = _unwrap(await repo.readDays());

    expect(days, hasLength(400));
    expect(days, isNot(contains('2024-01-01')));
  });
}
