import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cards = [
  DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
  DayCard(id: 'a', type: CardType.advice, body: 'b', source: 's'),
  DayCard(id: 'ba', type: CardType.basics, body: 'b', source: 's'),
  DayCard(id: 'r', type: CardType.reading, body: 'b', source: 's'),
];

class _FreshCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async => const Success(TodayCards(cards: _cards));
}

class _CourseProgressRepository implements CourseProgressRepository {
  var markCalls = 0;

  @override
  Future<Result<int>> currentTopic() async => const Success(1);

  @override
  Future<Result<void>> markCurrentTopicRead() async {
    markCalls++;
    return const Success(null);
  }
}

class _FailingCourseProgressRepository implements CourseProgressRepository {
  var markCalls = 0;

  @override
  Future<Result<int>> currentTopic() async => const Success(1);

  @override
  Future<Result<void>> markCurrentTopicRead() async {
    markCalls++;
    return const Failure(
      AppFailure('не удалось сохранить курс', kind: FailureKind.unknown),
    );
  }
}

class _FailingDayProgressRepository implements DayProgressRepository {
  static const _failure = AppFailure(
    'не удалось сохранить',
    kind: FailureKind.unknown,
  );

  @override
  Future<Result<DayProgress>> loadToday() async =>
      const Success(DayProgress(readTypes: {}, visitedDays: {}));

  @override
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) async => const Failure(_failure);
}

Future<ProviderContainer> _container(
  DayCardsRepository cards, {
  DayProgressRepository? progressRepository,
  CourseProgressRepository? courseRepository,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      dayCardsRepositoryProvider.overrideWithValue(cards),
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (progressRepository != null)
        dayProgressRepositoryProvider.overrideWithValue(progressRepository),
      if (courseRepository != null)
        courseProgressRepositoryProvider.overrideWithValue(courseRepository),
    ],
  );
  await container.read(todayCardsProvider.future);
  await container.read(dayProgressProvider.future);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('свежие карточки: чтение засчитывается, серия растёт', () async {
    final container = await _container(_FreshCardsRepository());
    final notifier = container.read(dayProgressProvider.notifier);

    for (final card in _cards) {
      await notifier.markRead(card.type);
    }

    final progress = container.read(dayProgressProvider).requireValue;
    expect(progress.allReadOf(_cards.map((c) => c.type)), isTrue);
    expect(progress.isLit(DateTime.now()), isTrue);
  });

  test('прочтение основ отмечает текущую тему курса', () async {
    final courseRepository = _CourseProgressRepository();
    final container = await _container(
      _FreshCardsRepository(),
      courseRepository: courseRepository,
    );

    await container
        .read(dayProgressProvider.notifier)
        .markRead(CardType.basics);

    expect(courseRepository.markCalls, 1);
  });

  test('ошибка записи прогресса всё равно отмечает тему курса', () async {
    final courseRepository = _CourseProgressRepository();
    final container = await _container(
      _FreshCardsRepository(),
      progressRepository: _FailingDayProgressRepository(),
      courseRepository: courseRepository,
    );

    final saved = await container
        .read(dayProgressProvider.notifier)
        .markRead(CardType.basics);

    expect(saved, isFalse);
    expect(courseRepository.markCalls, 1);
    expect(
      container.read(dayProgressProvider).requireValue,
      const DayProgress(readTypes: {}, visitedDays: {}),
    );
  });

  test('ошибка записи темы курса возвращает неуспех', () async {
    final courseRepository = _FailingCourseProgressRepository();
    final container = await _container(
      _FreshCardsRepository(),
      courseRepository: courseRepository,
    );

    final saved = await container
        .read(dayProgressProvider.notifier)
        .markRead(CardType.basics);

    expect(saved, isFalse);
    expect(courseRepository.markCalls, 1);
    expect(container.read(dayProgressProvider).requireValue.readTypes, {
      CardType.basics,
    });
  });
}
