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

  test('прочтение темы не меняет её в тот же день', () async {
    final r = repo(await prefsWith());

    await r.markCurrentTopicRead();

    expect(valueOf(await r.currentTopic()), 1);
  });

  test(
    'на следующий день после прочтения открывается следующая тема',
    () async {
      final r = repo(await prefsWith());

      await r.markCurrentTopicRead();
      now = DateTime(2026, 7, 29);

      expect(valueOf(await r.currentTopic()), 2);
      expect(valueOf(await r.currentTopic()), 2);
    },
  );

  test('пропущенные без прочтения дни не продвигают курс', () async {
    final prefs = await prefsWith();

    now = DateTime(2026, 8, 5);

    expect(valueOf(await repo(prefs).currentTopic()), 1);
  });

  test('прочтение переживает пересоздание репозитория', () async {
    final prefs = await prefsWith();
    await repo(prefs).markCurrentTopicRead();
    now = DateTime(2026, 7, 29);

    expect(valueOf(await repo(prefs).currentTopic()), 2);
  });

  test('дойдя до конца курса, на следующий день начинаем сначала', () async {
    final prefs = await prefsWith({
      'flutter.course_topic_v2': courseTopicCount,
    });
    final r = repo(prefs);

    await r.markCurrentTopicRead();
    now = DateTime(2026, 7, 29);

    expect(valueOf(await r.currentTopic()), 1);
  });

  test('старый ключ не мигрируется в новую схему', () async {
    final prefs = await prefsWith({'flutter.course_topic': courseTopicCount});

    expect(valueOf(await repo(prefs).currentTopic()), 1);
  });
}
