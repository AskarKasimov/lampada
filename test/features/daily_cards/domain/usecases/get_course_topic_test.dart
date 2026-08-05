import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/usecases/get_course_topic.dart';

class _CourseProgressRepository implements CourseProgressRepository {
  @override
  Future<Result<int>> advanceForToday() async => const Success(2);

  @override
  Future<Result<int>> currentTopic() async => const Success(1);
}

class _StaleDayCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async => Success(
    TodayCards(
      cards: const [
        DayCard(
          id: 'basics-2026-08-05',
          type: CardType.basics,
          body: 'Чужая тема',
          source: 'Азбука веры',
        ),
      ],
      staleDate: DateTime(2026, 8, 5),
    ),
  );
}

void main() {
  test('stale-кэш не становится темой курса', () async {
    final useCase = GetCourseTopic(
      _CourseProgressRepository(),
      _StaleDayCardsRepository(),
    );

    expect(await useCase(), isA<Failure<DayCard>>());
  });
}
