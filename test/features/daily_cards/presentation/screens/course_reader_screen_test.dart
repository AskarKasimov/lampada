import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CourseCardsRepository implements DayCardsRepository {
  final requestedTopics = <int>[];

  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    final topic = date.difference(DateTime(2026)).inDays + 1;
    requestedTopics.add(topic);
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

  Widget buildApp() => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      dayCardsRepositoryProvider.overrideWithValue(cards),
      dayProgressRepositoryProvider.overrideWithValue(progress),
      dayCardsProvider(
        dateKey(DateTime.now()),
      ).overrideWithValue(const AsyncData(TodayCards(cards: [_currentTopic]))),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const CourseReaderScreen(currentTopic: _currentTopic),
    ),
  );

  Future<void> pumpReader(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
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

  testWidgets('a left swipe shows the immediately preceding topic', (
    tester,
  ) async {
    await pumpReader(tester);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Тема 2'), findsOneWidget);
    expect(progress.readTypes, {CardType.basics});
    expect(progress.markReadCalls, [CardType.basics]);
  });

  testWidgets('a right swipe from the current topic stays on that topic', (
    tester,
  ) async {
    await pumpReader(tester);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Тема 3'), findsOneWidget);
    expect(find.text('Тема 2'), findsNothing);
  });
}
