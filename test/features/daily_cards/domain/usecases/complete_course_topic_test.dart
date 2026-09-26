import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_course_progress_repository.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/complete_course_topic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailOnceDayProgress implements DayProgressRepository {
  _FailOnceDayProgress(this.delegate);

  final DayProgressRepository delegate;
  bool failed = false;

  @override
  Future<Result<DayProgress>> loadToday() => delegate.loadToday();

  @override
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) {
    if (!failed) {
      failed = true;
      return Future.value(
        const Failure(
          AppFailure('Запись дня отклонена', kind: FailureKind.unknown),
        ),
      );
    }
    return delegate.markRead(type, date: date, markVisited: markVisited);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late PrefsCourseProgressRepository course;
  late PrefsDayProgressRepository days;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    course = PrefsCourseProgressRepository(prefs);
    days = PrefsDayProgressRepository(prefs);
  });

  test(
    'повторное завершение не увеличивает число тем и сохраняет позицию',
    () async {
      await course.saveCurrentTopic(3);
      final complete = CompleteCourseTopic(course, days);

      await complete(3);
      final result = await complete(3);

      expect((await course.completedTopics() as Success<Set<int>>).value, {3});
      expect((await course.currentTopic() as Success<int>).value, 3);
      expect(
        (result as Success<DayProgress>).value.isRead(CardType.basics),
        isTrue,
      );
      expect(result.value.isLit(DateTime.now()), isTrue);
    },
  );

  test(
    'повтор после ошибки дня восстанавливает активность без потери темы',
    () async {
      final complete = CompleteCourseTopic(course, _FailOnceDayProgress(days));

      expect(await complete(3), isA<Failure<DayProgress>>());
      expect((await course.completedTopics() as Success<Set<int>>).value, {3});
      expect(
        (await days.loadToday() as Success<DayProgress>).value.isRead(
          CardType.basics,
        ),
        isFalse,
      );

      expect(await complete(3), isA<Success<DayProgress>>());
      expect((await course.completedTopics() as Success<Set<int>>).value, {3});
      expect(
        (await days.loadToday() as Success<DayProgress>).value.isRead(
          CardType.basics,
        ),
        isTrue,
      );
    },
  );

  for (final topic in [0, -1, 366]) {
    test('некорректная тема $topic не засчитывает курс или день', () async {
      final result = await CompleteCourseTopic(course, days)(topic);

      expect(result, isA<Failure<DayProgress>>());
      expect(prefs.getString('course_progress_v4'), isNull);
      expect(
        (await days.loadToday() as Success<DayProgress>).value.visitedDays,
        isEmpty,
      );
    });
  }

  test('ошибка записи темы не засчитывает активность дня', () async {
    await prefs.setString(
      'course_progress_v4',
      jsonEncode({'completedTopics': 'повреждено'}),
    );

    final result = await CompleteCourseTopic(course, days)(3);

    expect(result, isA<Failure<DayProgress>>());
    expect(
      (await days.loadToday() as Success<DayProgress>).value.visitedDays,
      isEmpty,
    );
  });
}
