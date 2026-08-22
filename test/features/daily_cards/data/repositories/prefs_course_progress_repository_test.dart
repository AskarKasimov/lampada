import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/course_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/shared_preferences_stores.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith([
    Map<String, Object> seed = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(seed);
    return SharedPreferences.getInstance();
  }

  int valueOf(Result<int> result) => (result as Success<int>).value;

  PrefsCourseProgressRepository repo(SharedPreferences prefs) =>
      PrefsCourseProgressRepository(prefs);

  test('новый юзер начинает с первой темы', () async {
    // Раньше «Основы» брались по сегодняшней дате, и юзер, поставивший
    // приложение в июле, входил в курс с Темы 209 — то есть с середины.
    final result = await repo(await prefsWith()).currentTopic();

    expect(valueOf(result), 1);
  });

  test('сохраняет последнюю открытую тему', () async {
    final r = repo(await prefsWith());

    await r.saveCurrentTopic(2);

    expect(valueOf(await r.currentTopic()), 2);
  });

  test(
    'последняя из последовательных записей становится текущей темой',
    () async {
      final r = repo(await prefsWith());

      await r.saveCurrentTopic(2);
      await r.saveCurrentTopic(3);
      await r.saveCurrentTopic(4);

      expect(valueOf(await r.currentTopic()), 4);
    },
  );

  test('быстрые свайпы сохраняют последнюю из увиденных тем', () async {
    final r = repo(await prefsWith());

    await Future.wait([r.saveCurrentTopic(2), r.saveCurrentTopic(3)]);

    expect(valueOf(await r.currentTopic()), 3);
  });

  test('выбранная тема переживает пересоздание репозитория', () async {
    final prefs = await prefsWith();
    await repo(prefs).saveCurrentTopic(2);

    expect(valueOf(await repo(prefs).currentTopic()), 2);
  });

  test('последняя тема курса остаётся выбранной', () async {
    final prefs = await prefsWith({
      'flutter.course_progress_v4': jsonEncode({'topic': courseTopicCount}),
    });
    final r = repo(prefs);

    await r.saveCurrentTopic(courseTopicCount);

    expect(valueOf(await r.currentTopic()), courseTopicCount);
  });

  test('запись прошлой схемы читается, лишний readOn игнорируется', () async {
    // Дневного гарда больше нет, поле readOn перестали писать. Записи, где
    // оно ещё лежит, должны читаться как обычно — иначе пришлось бы поднимать
    // версию ключа на пустом месте.
    final prefs = await prefsWith({
      'flutter.course_progress_v4': jsonEncode({
        'topic': 7,
        'readOn': '2026-07-27',
      }),
    });

    expect(valueOf(await repo(prefs).currentTopic()), 7);
  });

  test('ключи прошлой схемы не мигрируются', () async {
    final prefs = await prefsWith({
      'flutter.course_progress_v3': jsonEncode({
        'topic': 42,
        'readOn': '2026-07-27',
      }),
    });

    expect(valueOf(await repo(prefs).currentTopic()), 1);
  });

  test('прогресс неверного типа в prefs отдаёт Failure', () async {
    final prefs = await prefsWith({'flutter.course_progress_v4': <String>[]});

    expect(await repo(prefs).currentTopic(), isA<Failure<int>>());
  });

  test('не подтверждает прочтение, если prefs отклонил запись', () async {
    SharedPreferences.resetStatic();
    installSharedPreferencesStore(RejectingWriteStore());
    final failing = repo(await SharedPreferences.getInstance());
    addTearDown(() => SharedPreferences.setMockInitialValues({}));

    expect(await failing.saveCurrentTopic(2), isA<Failure<void>>());
  });
}
