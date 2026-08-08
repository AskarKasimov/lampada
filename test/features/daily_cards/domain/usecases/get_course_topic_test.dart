import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/get_course_topic.dart';

class _CourseProgressRepository implements CourseProgressRepository {
  @override
  Future<Result<void>> markCurrentTopicRead() async => const Success(null);

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
  test('загружает запрошенную тему с её номером в id', () async {
    final cards = _FreshDayCardsRepository();
    final useCase = GetCourseTopic(_CourseProgressRepository(), cards);

    final result = await useCase.forTopic(64);

    expect(cards.requestedDate, DateTime(2026, 3, 5));
    expect(result, isA<Success<DayCard>>());
    expect((result as Success<DayCard>).value.id, 'basics-topic-64');
  });
}
