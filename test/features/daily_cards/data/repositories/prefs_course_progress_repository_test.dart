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

  test(
    'страница хранится вместе с темой и переживает пересоздание репозитория',
    () async {
      final prefs = await prefsWith();
      await repo(prefs).saveCurrentTopic(3, page: 2);
      await repo(prefs).completeTopic(3);
      expect((await repo(prefs).currentPage(3) as Success<int?>).value, 2);
      expect((await repo(prefs).currentPage(4) as Success<int?>).value, isNull);
      await repo(prefs).saveCurrentTopic(4);
      expect((await repo(prefs).currentPage(4) as Success<int?>).value, 0);
    },
  );

  test(
    'старое место без страницы сохраняется как устаревшее, а не страница ноль',
    () async {
      final r = repo(
        await prefsWith({'flutter.course_progress_v4': '{"topic":209}'}),
      );
      expect((await r.currentPage(209) as Success<int?>).value, isNull);
    },
  );

  test('чистая установка не начинает курс', () async {
    final prefs = await prefsWith();
    final r = repo(prefs);
    expect((await r.hasStarted() as Success<bool>).value, isFalse);
    await r.currentTopic();
    await r.completedTopics();
    expect((await r.hasStarted() as Success<bool>).value, isFalse);
    expect(prefs.getString('course_progress_v4'), isNull);
  });

  test(
    'явное начало сохраняет первую страницу и делает курс активным',
    () async {
      final r = repo(await prefsWith());
      await r.saveCurrentTopic(1);
      expect((await r.hasStarted() as Success<bool>).value, isTrue);
    },
  );

  test('старое сохранённое место сохраняет активный курс', () async {
    final r = repo(
      await prefsWith({'flutter.course_progress_v4': '{"topic":209}'}),
    );
    expect((await r.hasStarted() as Success<bool>).value, isTrue);
  });

  test(
    'завершённые темы старой записи также сохраняют активный курс',
    () async {
      final r = repo(
        await prefsWith({
          'flutter.course_progress_v4': '{"completedTopics":[1]}',
        }),
      );
      expect((await r.hasStarted() as Success<bool>).value, isTrue);
    },
  );

  test('новый юзер начинает с первой темы', () async {
    // Раньше «Основы» брались по сегодняшней дате, и юзер, поставивший
    // приложение в июле, входил в курс с Темы 209 — то есть с середины.
    final result = await repo(await prefsWith()).currentTopic();

    expect(valueOf(result), 1);
  });

  test('старое место чтения не превращается в завершённые темы', () async {
    final r = repo(
      await prefsWith({
        'flutter.course_progress_v4': jsonEncode({'topic': 209}),
      }),
    );

    expect(valueOf(await r.currentTopic()), 209);
    expect((await r.completedTopics() as Success<Set<int>>).value, isEmpty);
  });

  test('чередование отметок и быстрых свайпов не теряет прогресс', () async {
    final r = repo(await prefsWith());

    await Future.wait([
      r.completeTopic(1),
      r.saveCurrentTopic(2),
      r.completeTopic(3),
      r.saveCurrentTopic(4),
    ]);

    expect(valueOf(await r.currentTopic()), 4);
    expect((await r.completedTopics() as Success<Set<int>>).value, {1, 3});
  });

  test('сохраняет последнюю открытую тему', () async {
    final r = repo(await prefsWith());

    await r.saveCurrentTopic(2);

    expect(valueOf(await r.currentTopic()), 2);
  });

  test('просмотр другой темы сохраняет отметки прочитанного', () async {
    final prefs = await prefsWith({
      'flutter.course_progress_v4': jsonEncode({
        'topic': 3,
        'completedTopics': [1, 3],
      }),
    });

    await repo(prefs).saveCurrentTopic(2);

    final stored =
        jsonDecode(prefs.getString('course_progress_v4')!)
            as Map<String, dynamic>;
    expect(stored['topic'], 2);
    expect(stored['completedTopics'], [1, 3]);
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

  test(
    'отклонённая отметка не становится завершённой темой в памяти',
    () async {
      SharedPreferences.resetStatic();
      installSharedPreferencesStore(RejectingWriteStore());
      final failing = repo(await SharedPreferences.getInstance());
      addTearDown(() => SharedPreferences.setMockInitialValues({}));

      expect(await failing.completeTopic(3), isA<Failure<void>>());
      expect(
        (await failing.completedTopics() as Success<Set<int>>).value,
        isEmpty,
      );
    },
  );
}
