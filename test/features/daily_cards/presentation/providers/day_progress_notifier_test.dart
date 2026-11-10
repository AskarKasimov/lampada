import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_event.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
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

import '../../../../support/fake_analytics.dart';

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
  @override
  Future<Result<bool>> hasStarted() async => const Success(false);

  @override
  Future<Result<int?>> currentPage(int topic) async => const Success(null);

  @override
  Future<Result<Set<int>>> completedTopics() async => const Success({});

  @override
  Future<Result<void>> completeTopic(int topic) => saveCurrentTopic(topic);

  final savedTopics = <int>[];

  @override
  Future<Result<int>> currentTopic() async => const Success(1);

  @override
  Future<Result<void>> saveCurrentTopic(int topic, {int page = 0}) async {
    savedTopics.add(topic);
    return const Success(null);
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

  @override
  Future<Result<DayProgress>> completeWisdom({
    DateTime? date,
    bool markVisited = true,
  }) async => const Failure(_failure);

  @override
  Future<Result<DayProgress>> markVisited({DateTime? date}) async =>
      const Failure(_failure);
}

Future<ProviderContainer> _container(
  DayCardsRepository cards, {
  DayProgressRepository? progressRepository,
  CourseProgressRepository? courseRepository,
  FakeAnalytics? analytics,
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
      analyticsProvider.overrideWithValue(analytics ?? FakeAnalytics()),
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

  test('completeWisdom отмечает завершение и зажигает день', () async {
    final container = await _container(_FreshCardsRepository());

    final saved = await container
        .read(dayProgressProvider.notifier)
        .completeWisdom(date: DateTime.now());

    final progress = container.read(dayProgressProvider).requireValue;
    expect(saved, isTrue);
    expect(progress.isWisdomCompletedOn(DateTime.now()), isTrue);
    expect(progress.isLit(DateTime.now()), isTrue);
    expect(progress.readTypes, isEmpty);
  });

  group('lightLamp', () {
    test('зажигает сегодняшний день и пишет lamp_lit с источником', () async {
      final analytics = FakeAnalytics();
      final container = await _container(
        _FreshCardsRepository(),
        analytics: analytics,
      );

      final lit = await container
          .read(dayProgressProvider.notifier)
          .lightLamp(LampSource.story, contentDate: DateTime.now());

      final progress = container.read(dayProgressProvider).requireValue;
      expect(lit?.litNow, isTrue);
      expect(lit?.before.isLit(DateTime.now()), isFalse);
      expect(progress.isLit(DateTime.now()), isTrue);
      expect(progress.readTypes, isEmpty);
      expect(analytics.single('lamp_lit'), {
        'source': 'story',
        'streak': 1,
        'restarted': true,
      });
    });

    test('уже горящий день не пишет lamp_lit повторно', () async {
      final analytics = FakeAnalytics();
      final container = await _container(
        _FreshCardsRepository(),
        analytics: analytics,
      );
      final notifier = container.read(dayProgressProvider.notifier);

      await notifier.lightLamp(LampSource.bible);
      final again = await notifier.lightLamp(LampSource.story);

      expect(again?.litNow, isFalse);
      expect(analytics.single('lamp_lit')['source'], 'bible');
    });

    test('раздел прошлого дня лампаду не зажигает', () async {
      final analytics = FakeAnalytics();
      final container = await _container(
        _FreshCardsRepository(),
        analytics: analytics,
      );
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final lit = await container
          .read(dayProgressProvider.notifier)
          .lightLamp(LampSource.story, contentDate: yesterday);

      final progress = container.read(dayProgressProvider).requireValue;
      expect(lit?.litNow, isFalse);
      expect(progress.visitedDays, isEmpty);
      expect(analytics.names, isNot(contains('lamp_lit')));
    });

    test('сбой записи не пишет lamp_lit', () async {
      final analytics = FakeAnalytics();
      final container = await _container(
        _FreshCardsRepository(),
        progressRepository: _FailingDayProgressRepository(),
        analytics: analytics,
      );

      final lit = await container
          .read(dayProgressProvider.notifier)
          .lightLamp(LampSource.story);

      expect(lit, isNull);
      expect(analytics.names, isNot(contains('lamp_lit')));
    });
  });

  test('прочтение основ не сдвигает тему личного курса', () async {
    final courseRepository = _CourseProgressRepository();
    final container = await _container(
      _FreshCardsRepository(),
      courseRepository: courseRepository,
    );

    await container
        .read(dayProgressProvider.notifier)
        .markRead(CardType.basics);

    expect(courseRepository.savedTopics, isEmpty);
  });

  test('ошибка записи прогресса не меняет тему личного курса', () async {
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
    expect(courseRepository.savedTopics, isEmpty);
    expect(
      container.read(dayProgressProvider).requireValue,
      const DayProgress(readTypes: {}, visitedDays: {}),
    );
  });
}
