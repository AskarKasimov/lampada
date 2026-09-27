import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/get_course_topic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CourseProgressRepository implements CourseProgressRepository {
  @override
  Future<Result<bool>> hasStarted() async => const Success(false);

  @override
  Future<Result<int?>> currentPage(int topic) async => const Success(null);

  @override
  Future<Result<Set<int>>> completedTopics() async => const Success({});

  @override
  Future<Result<void>> completeTopic(int topic) => saveCurrentTopic(topic);

  @override
  Future<Result<void>> saveCurrentTopic(int topic, {int page = 0}) async =>
      const Success(null);

  @override
  Future<Result<int>> currentTopic() async => const Success(1);
}

class _FreshDayCardsRepository implements DayCardsRepository {
  DateTime? requestedDate;

  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    requestedDate = date;
    return const Success(
      TodayCards(
        cards: [
          DayCard(
            id: 'basics-2026-03-05',
            type: CardType.basics,
            body: 'Тема 64',
            source: 'Азбука веры',
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final example in [
    (topic: 3, completed: [1, 2, 3], next: 4, date: DateTime(2026, 1, 4)),
    (topic: 209, completed: <int>[], next: 209, date: DateTime(2026, 7, 28)),
    (
      topic: 365,
      completed: List.generate(365, (i) => i + 1)..remove(2),
      next: 2,
      date: DateTime(2026, 1, 2),
    ),
    (
      topic: 365,
      completed: List.generate(365, (i) => i + 1),
      next: 365,
      date: DateTime(2026, 12, 31),
    ),
  ]) {
    test(
      'продолжение с темы ${example.topic} при ${example.completed.length} отметках открывает ${example.next}',
      () async {
        SharedPreferences.setMockInitialValues({
          'flutter.course_progress_v4': jsonEncode({
            'topic': example.topic,
            'completedTopics': example.completed,
          }),
        });
        final progress = PrefsCourseProgressRepository(
          await SharedPreferences.getInstance(),
        );
        final cards = _FreshDayCardsRepository();

        final result = await GetCourseTopic(progress, cards)();

        expect(cards.requestedDate, example.date);
        expect(
          (result as Success<DayCard>).value.id,
          'basics-topic-${example.next}',
        );
      },
    );
  }

  test(
    'сохранённая страница завершённой темы имеет приоритет над следующей темой',
    () async {
      SharedPreferences.setMockInitialValues({
        'flutter.course_progress_v4':
            '{"topic":3,"page":1,"completedTopics":[1,2,3]}',
      });
      final progress = PrefsCourseProgressRepository(
        await SharedPreferences.getInstance(),
      );
      final cards = _FreshDayCardsRepository();
      final result = await GetCourseTopic(progress, cards)();
      expect((result as Success<DayCard>).value.id, 'basics-topic-3');
    },
  );

  test('загружает запрошенную тему с её номером в id', () async {
    final cards = _FreshDayCardsRepository();
    final useCase = GetCourseTopic(_CourseProgressRepository(), cards);

    final result = await useCase.forTopic(64);

    expect(cards.requestedDate, DateTime(2026, 3, 5));
    expect(result, isA<Success<DayCard>>());
    expect((result as Success<DayCard>).value.id, 'basics-topic-64');
  });
}
