import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CourseCardsRepository implements DayCardsRepository {
  _CourseCardsRepository({Map<int, int> failuresRemaining = const {}})
    : failuresRemaining = Map.of(failuresRemaining);

  final requestedTopics = <int>[];
  final Map<int, int> failuresRemaining;

  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    final topic = date.difference(DateTime(2026)).inDays + 1;
    requestedTopics.add(topic);
    final failures = failuresRemaining[topic] ?? 0;
    if (failures > 0) {
      failuresRemaining[topic] = failures - 1;
      return Failure(
        AppFailure('Тема $topic недоступна', kind: FailureKind.network),
      );
    }
    return Success(
      TodayCards(
        cards: [
          DayCard(
            id: 'source-basics-$topic',
            type: CardType.basics,
            body: 'Тема $topic',
            source: 'Азбука веры',
          ),
        ],
      ),
    );
  }
}

class _ProgressRepository implements DayProgressRepository {
  final readTypes = <CardType>{};
  final markReadCalls = <CardType>[];

  @override
  Future<Result<DayProgress>> loadToday() async =>
      Success(DayProgress(readTypes: readTypes, visitedDays: const {}));

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    markReadCalls.add(type);
    readTypes.add(type);
    return Success(DayProgress(readTypes: readTypes, visitedDays: const {}));
  }
}

class _FailingCourseProgressRepository implements CourseProgressRepository {
  @override
  Future<Result<int>> currentTopic() async => const Success(3);

  @override
  Future<Result<void>> markCurrentTopicRead() async => const Failure(
    AppFailure('Не удалось сохранить тему курса', kind: FailureKind.unknown),
  );
}

const _currentTopic = DayCard(
  id: 'basics-topic-3',
  type: CardType.basics,
  body: 'Тема 3',
  source: 'Азбука веры',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late _CourseCardsRepository cards;
  late _ProgressRepository progress;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cards = _CourseCardsRepository();
    progress = _ProgressRepository();
  });

  Widget buildApp({
    DayCard currentTopic = _currentTopic,
    bool showLauncher = false,
    CourseProgressRepository? courseProgressRepository,
  }) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      dayCardsRepositoryProvider.overrideWithValue(cards),
      dayProgressRepositoryProvider.overrideWithValue(progress),
      if (courseProgressRepository != null)
        courseProgressRepositoryProvider.overrideWithValue(
          courseProgressRepository,
        ),
      dayCardsProvider(
        dateKey(DateTime.now()),
      ).overrideWithValue(AsyncData(TodayCards(cards: [currentTopic]))),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: showLauncher
          ? Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CourseReaderScreen(currentTopic: currentTopic),
                    ),
                  ),
                  child: const Text('Открыть основы'),
                ),
              ),
            )
          : CourseReaderScreen(currentTopic: currentTopic),
    ),
  );

  Future<void> pumpReader(
    WidgetTester tester, {
    DayCard currentTopic = _currentTopic,
  }) async {
    await tester.pumpWidget(buildApp(currentTopic: currentTopic));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the supplied current topic and records its progress', (
    tester,
  ) async {
    await pumpReader(tester);

    expect(find.text('Тема 3'), findsOneWidget);
    expect(progress.readTypes, {CardType.basics});
    expect(cards.requestedTopics, contains(2));
  });

  testWidgets('показывает ошибку, если тема курса не сохранилась', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(courseProgressRepository: _FailingCourseProgressRepository()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Не удалось сохранить прогресс'), findsOneWidget);
  });

  testWidgets('keeps the course title visible in the reader header', (
    tester,
  ) async {
    await pumpReader(tester);

    expect(find.text('Основы веры'), findsOneWidget);
  });

  testWidgets('uses the reader header instead of the repeated basics badge', (
    tester,
  ) async {
    await pumpReader(tester);

    expect(find.text('Основы'), findsNothing);
  });

  testWidgets('shows the course position and history swipe hint', (
    tester,
  ) async {
    await pumpReader(tester);

    expect(find.text('← Предыдущие темы · Тема 3 из 365'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('← Предыдущие темы · Тема 2 из 365'), findsOneWidget);
  });

  testWidgets('a fast downward swipe closes the course reader', (tester) async {
    await tester.pumpWidget(buildApp(showLauncher: true));
    await tester.tap(find.text('Открыть основы'));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CourseReaderScreen),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CourseReaderScreen), findsNothing);
    expect(find.text('Открыть основы'), findsOneWidget);
  });

  testWidgets('a right swipe shows the immediately preceding topic', (
    tester,
  ) async {
    await pumpReader(tester);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Тема 2'), findsOneWidget);
    expect(progress.readTypes, {CardType.basics});
    expect(progress.markReadCalls, [CardType.basics]);
  });

  testWidgets('a left swipe from the current topic stays on that topic', (
    tester,
  ) async {
    await pumpReader(tester);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Тема 3'), findsOneWidget);
    expect(find.text('Тема 2'), findsNothing);
  });

  testWidgets('a failed historical topic can retry without reloading others', (
    tester,
  ) async {
    cards = _CourseCardsRepository(failuresRemaining: {2: 1});
    await pumpReader(tester);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Тема недоступна'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    final topicOneRequestsBeforeRetry = cards.requestedTopics
        .where((topic) => topic == 1)
        .length;

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Тема 2'), findsOneWidget);
    expect(cards.requestedTopics.where((topic) => topic == 2), hasLength(2));
    expect(
      cards.requestedTopics.where((topic) => topic == 1),
      hasLength(topicOneRequestsBeforeRetry),
    );
  });

  testWidgets(
    'the first course topic has no earlier page or topic zero request',
    (tester) async {
      const firstTopic = DayCard(
        id: 'basics-topic-1',
        type: CardType.basics,
        body: 'Тема 1',
        source: 'Азбука веры',
      );
      await pumpReader(tester, currentTopic: firstTopic);

      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Тема 1'), findsOneWidget);
      expect(cards.requestedTopics, isEmpty);
      expect(cards.requestedTopics, isNot(contains(0)));
    },
  );
}
