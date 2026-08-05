import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/course_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith([
    Map<String, Object> seed = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(seed);
    return SharedPreferences.getInstance();
  }

  int valueOf(Result<int> result) => (result as Success<int>).value;

  var now = DateTime(2026, 7, 28);
  PrefsCourseProgressRepository repo(SharedPreferences prefs) =>
      PrefsCourseProgressRepository(prefs, clock: () => now);

  setUp(() => now = DateTime(2026, 7, 28));

  test('новый юзер начинает с первой темы', () async {
    // Раньше «Основы» брались по сегодняшней дате, и юзер, поставивший
    // приложение в июле, входил в курс с Темы 209 — то есть с середины.
    final result = await repo(await prefsWith()).currentTopic();

    expect(valueOf(result), 1);
  });

  test('продвижение даёт следующую тему', () async {
    final r = repo(await prefsWith());

    expect(valueOf(await r.advanceForToday()), 2);
    expect(valueOf(await r.currentTopic()), 2);
  });

  test('за один день курс сдвигается только раз', () async {
    // Иначе перечитывание карточки пролистывало бы курс вперёд.
    final r = repo(await prefsWith());

    await r.advanceForToday();
    await r.advanceForToday();
    await r.advanceForToday();

    expect(valueOf(await r.currentTopic()), 2);
  });

  test('на следующий день курс снова сдвигается', () async {
    final prefs = await prefsWith();

    await repo(prefs).advanceForToday();
    now = DateTime(2026, 7, 29);
    await repo(prefs).advanceForToday();

    expect(valueOf(await repo(prefs).currentTopic()), 3);
  });

  test('прогресс переживает пересоздание репозитория', () async {
    final prefs = await prefsWith();
    await repo(prefs).advanceForToday();

    expect(valueOf(await repo(prefs).currentTopic()), 2);
  });

  test('дойдя до конца курса, начинаем сначала', () async {
    final prefs = await prefsWith({'flutter.course_topic': courseTopicCount});

    expect(valueOf(await repo(prefs).advanceForToday()), 1);
  });

  test('мусорный номер в prefs не ломает курс', () async {
    final prefs = await prefsWith({'flutter.course_topic': 0});

    expect(valueOf(await repo(prefs).currentTopic()), 1);
  });
}
