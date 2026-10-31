import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/day_story/data/repositories/prefs_story_progress_repository.dart';
import 'package:lampada/features/day_story/domain/entities/story_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

StoryProgress _unwrap(Result<StoryProgress> r) =>
    (r as Success<StoryProgress>).value;

const _first = 'https://azbyka.ru/days/sv-foma-malein';
const _second = 'https://azbyka.ru/days/sv-akakij-sinajskij';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefs([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('свежая установка: ни одного прочитанного рассказа', () async {
    final repo = PrefsStoryProgressRepository(await prefs());

    final progress = _unwrap(await repo.load());

    expect(progress.readDays, isEmpty);
    expect(progress.readOn(DateTime(2026, 7, 17)), isEmpty);
  });

  test('отметка дня переживает пересоздание репозитория', () async {
    // Напоминание о святом не должно приходить тому, кто уже прочитал.
    final store = await prefs();
    await PrefsStoryProgressRepository(
      store,
    ).markRead(DateTime(2026, 7, 17), _first);

    final progress = _unwrap(await PrefsStoryProgressRepository(store).load());

    expect(progress.readDays, {'2026-07-17'});
    expect(progress.readOn(DateTime(2026, 7, 17)), {_first});
  });

  test('рассказы дня отмечаются каждый отдельно', () async {
    final repo = PrefsStoryProgressRepository(await prefs());

    await repo.markRead(DateTime(2026, 7, 17, 9), _first);
    final progress = _unwrap(
      await repo.markRead(DateTime(2026, 7, 17, 20), _second),
    );

    expect(progress.readDays, {'2026-07-17'});
    expect(progress.readOn(DateTime(2026, 7, 17)), {_first, _second});
    // Тот же святой в другой день читается заново.
    expect(progress.readOn(DateTime(2026, 7, 18)), isEmpty);
  });

  test('повторная отметка того же рассказа не дублирует его', () async {
    final store = await prefs();
    final repo = PrefsStoryProgressRepository(store);

    await repo.markRead(DateTime(2026, 7, 17, 9), _first);
    await repo.markRead(DateTime(2026, 7, 17, 20), _first);

    expect(store.getStringList('story_read_days'), ['2026-07-17']);
    expect(store.getStringList('story_read_urls'), ['2026-07-17 $_first']);
  });

  test('день, прочитанный до очереди святых, остаётся прочитанным', () async {
    // Прежние версии помнили только день: напоминание о нём не вернётся.
    final repo = PrefsStoryProgressRepository(
      await prefs({
        'flutter.story_read_days': ['2026-07-17'],
      }),
    );

    final progress = _unwrap(await repo.load());

    expect(progress.readDays, {'2026-07-17'});
    expect(progress.readOn(DateTime(2026, 7, 17)), isEmpty);
  });

  test('история ограничена, prefs не растут вечно', () async {
    final store = await prefs();
    final repo = PrefsStoryProgressRepository(store);
    final start = DateTime(2024);

    for (var i = 0; i < 405; i++) {
      await repo.markRead(start.add(Duration(days: i)), _first);
    }
    final progress = _unwrap(await repo.load());

    expect(progress.readDays, hasLength(400));
    expect(progress.readDays, isNot(contains('2024-01-01')));
    expect(progress.readOn(DateTime(2024)), isEmpty);
    expect(store.getStringList('story_read_urls'), hasLength(400));
  });
}
