import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/app_pill_badge.dart';
import 'package:lampada/core/widgets/app_share_button.dart';
import 'package:lampada/features/bookmarks/data/repositories/prefs_bookmarks_repository.dart';
import 'package:lampada/features/bookmarks/domain/entities/bookmark.dart';
import 'package:lampada/features/daily_cards/data/repositories/prefs_course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/course_progress_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
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
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) async {
    markReadCalls.add(type);
    readTypes.add(type);
    return Success(DayProgress(readTypes: readTypes, visitedDays: const {}));
  }
}

class _FailingCourseProgressRepository implements CourseProgressRepository {
  int completeCalls = 0;

  @override
  Future<Result<bool>> hasStarted() async => const Success(false);

  @override
  Future<Result<int?>> currentPage(int topic) async => const Success(null);

  @override
  Future<Result<Set<int>>> completedTopics() async => const Success({});

  @override
  Future<Result<void>> completeTopic(int topic) {
    completeCalls++;
    return saveCurrentTopic(topic);
  }

  @override
  Future<Result<int>> currentTopic() async => const Success(3);

  @override
  Future<Result<void>> saveCurrentTopic(int topic, {int page = 0}) async =>
      const Failure(
        AppFailure(
          'Не удалось сохранить тему курса',
          kind: FailureKind.unknown,
        ),
      );
}

class _DelayedCourseProgressRepository implements CourseProgressRepository {
  @override
  Future<Result<bool>> hasStarted() async => const Success(false);

  @override
  Future<Result<int?>> currentPage(int topic) async => const Success(null);

  @override
  Future<Result<Set<int>>> completedTopics() async => const Success({});

  @override
  Future<Result<void>> completeTopic(int topic) => saveCurrentTopic(topic);

  final saved = Completer<Result<void>>();

  @override
  Future<Result<int>> currentTopic() async => const Success(3);

  @override
  Future<Result<void>> saveCurrentTopic(int topic, {int page = 0}) =>
      saved.future;
}

class _DelayedNextCards extends _CourseCardsRepository {
  final response = Completer<Result<TodayCards>>();

  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) {
    if (date.difference(DateTime(2026)).inDays + 1 == 4) {
      return response.future;
    }
    return super.getCardsFor(date, forceRefresh: forceRefresh);
  }
}

class _FailOncePosition extends PrefsCourseProgressRepository {
  _FailOncePosition(super.prefs);
  var failed = false;

  @override
  Future<Result<void>> saveCurrentTopic(int topic, {int page = 0}) async {
    if (!failed) {
      failed = true;
      return const Failure(
        AppFailure('Запись отклонена', kind: FailureKind.unknown),
      );
    }
    return super.saveCurrentTopic(topic, page: page);
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

  testWidgets(
    'info на карточках курса открывает описание и возвращает к чтению',
    (tester) async {
      await pumpReader(tester);
      final info = find.byTooltip('О курсе');
      expect(info, findsOneWidget);
      expect(
        tester.getTopRight(info).dx,
        greaterThan(tester.getSize(find.byType(CourseReaderScreen)).width - 80),
      );
      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Тема 4'), findsOneWidget);
      expect(info, findsOneWidget);

      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.text('О курсе'), findsOneWidget);
      expect(find.text('Источник: «Азбука веры»'), findsOneWidget);
      expect(find.text('Продолжить'), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Тема 4'), findsOneWidget);
    },
  );

  testWidgets('закладки страниц одной темы сохраняются независимо', (
    tester,
  ) async {
    await pumpReader(
      tester,
      currentTopic: _currentTopic.copyWith(body: 'Первая мысль. Вторая мысль.'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Сохранить в копилку'));
    await tester.pumpAndSettle();

    final repository = PrefsBookmarksRepository(prefs);
    var saved = (await repository.load() as Success<List<Bookmark>>).value;
    expect(saved, hasLength(1));
    expect(saved.single.text, 'Первая мысль.');
    expect(saved.single.source, 'Азбука веры');

    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Сохранить в копилку'), findsOneWidget);
    await tester.tap(find.byTooltip('Сохранить в копилку'));
    await tester.pumpAndSettle();
    saved = (await repository.load() as Success<List<Bookmark>>).value;
    expect(
      saved.map((bookmark) => bookmark.text),
      unorderedEquals(['Первая мысль.', 'Вторая мысль.']),
    );
    expect(saved.map((bookmark) => bookmark.id).toSet(), hasLength(2));

    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Убрать из копилки'));
    await tester.pumpAndSettle();
    saved = (await repository.load() as Success<List<Bookmark>>).value;
    expect(saved, hasLength(1));
    expect(saved.single.text, 'Вторая мысль.');
  });

  testWidgets('ошибка предыдущей темы не блокирует загрузку следующей', (
    tester,
  ) async {
    cards = _CourseCardsRepository(failuresRemaining: {2: 1});
    await pumpReader(tester);
    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('Тема недоступна'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(find.text('Тема 4'), findsOneWidget);
  });

  testWidgets(
    'повторный переход к следующей теме не отмечает день второй раз',
    (tester) async {
      await pumpReader(tester);
      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(0, 500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(progress.markReadCalls, [CardType.basics]);
    },
  );

  testWidgets('завершение с ошибкой предлагает повторить сохранение', (
    tester,
  ) async {
    final failing = _FailingCourseProgressRepository();
    await tester.pumpWidget(buildApp(courseProgressRepository: failing));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось сохранить прогресс'), findsOneWidget);
    expect(failing.completeCalls, 1);
    expect(progress.markReadCalls, isEmpty);
    await tester.tap(find.text('Повторить сохранение'));
    await tester.pumpAndSettle();
    expect(failing.completeCalls, 2);
  });

  testWidgets('следующая тема повторяет загрузку без пропуска завершения', (
    tester,
  ) async {
    cards = _CourseCardsRepository(failuresRemaining: {4: 1});
    await pumpReader(tester);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Тема недоступна'), findsOneWidget);
    expect(progress.markReadCalls, [CardType.basics]);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Тема 4'), findsOneWidget);
    expect(progress.markReadCalls, [CardType.basics]);
  });

  testWidgets('ошибка фоновой загрузки запускает текущую границу', (
    tester,
  ) async {
    final delayed = _DelayedNextCards();
    cards = delayed;
    await pumpReader(tester);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 500));
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(PageView), const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 500));
    }
    delayed.response.complete(
      const Failure(AppFailure('Ошибка загрузки', kind: FailureKind.network)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Тема 2'), findsOneWidget);
  });

  testWidgets('ошибка позиции повторяет запись на следующем чанке', (
    tester,
  ) async {
    await prefs.setString('course_progress_v4', '{"topic":3}');
    await tester.pumpWidget(
      buildApp(
        currentTopic: _currentTopic.copyWith(
          body: 'Первая мысль.\n\nВторая мысль.',
        ),
        courseProgressRepository: _FailOncePosition(prefs),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось сохранить место чтения'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final saved = await PrefsCourseProgressRepository(prefs).currentTopic();
    expect((saved as Success<int>).value, 4);
  });

  testWidgets('короткие абзацы листаются отдельно, без страницы завершения', (
    tester,
  ) async {
    await pumpReader(
      tester,
      currentTopic: _currentTopic.copyWith(
        body: 'Первый абзац.\n\nВторой абзац.',
      ),
    );
    expect(find.text('Первый абзац.'), findsOneWidget);
    expect(tester.widget<ProgressDots>(find.byType(ProgressDots)).count, 2);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Второй абзац.'), findsOneWidget);
    expect(progress.readTypes, isEmpty);
    final dots = tester.widget<ProgressDots>(find.byType(ProgressDots));
    expect(dots.count, 2);
    expect(dots.currentIndex, 1);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Тема прочитана'), findsNothing);
    expect(find.text('Тема 4'), findsOneWidget);
    expect(progress.readTypes, {CardType.basics});
  });

  testWidgets('shows the supplied current topic', (tester) async {
    await pumpReader(tester);

    expect(find.text('Тема 3'), findsOneWidget);
    expect(cards.requestedTopics, contains(2));
  });

  testWidgets('открытие не засчитывает тему, переход к следующей засчитывает', (
    tester,
  ) async {
    await pumpReader(tester);
    expect(progress.readTypes, isEmpty);
    expect(find.text('Прочитано'), findsNothing);
    expect(cards.requestedTopics, isNot(contains(4)));
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Тема 4'), findsOneWidget);
    expect(progress.readTypes, {CardType.basics});
    final stored =
        jsonDecode(prefs.getString('course_progress_v4')!)
            as Map<String, dynamic>;
    expect(stored['completedTopics'], [3]);
  });

  testWidgets('вмещающееся предложение длиннее 150 не требует полного экрана', (
    tester,
  ) async {
    final body = '${List.filled(40, 'Слово').join(' ')}.';
    await pumpReader(tester, currentTopic: _currentTopic.copyWith(body: body));
    expect(find.text(body), findsOneWidget);
    expect(find.byTooltip('Открыть полный текст'), findsNothing);
  });

  testWidgets('длинное предложение открывается полностью и не разбивается', (
    tester,
  ) async {
    final body = '${List.filled(400, 'Слово').join(' ')}.';
    await pumpReader(tester, currentTopic: _currentTopic.copyWith(body: body));
    expect(find.text(body), findsNothing);
    expect(tester.widget<ProgressDots>(find.byType(ProgressDots)).count, 1);
    expect(find.byTooltip('Открыть полный текст'), findsOneWidget);
    await tester.tap(find.byTooltip('Открыть полный текст'));
    await tester.pumpAndSettle();
    expect(find.text(body), findsOneWidget);
    expect(find.text('— Азбука веры'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(progress.readTypes, isEmpty);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Тема 4'), findsOneWidget);
  });

  testWidgets(
    'источник скрыт, сохранён для отправки, заголовок только номер темы',
    (tester) async {
      await pumpReader(
        tester,
        currentTopic: _currentTopic.copyWith(title: 'Первые слова темы'),
      );
      expect(find.text('— Азбука веры'), findsNothing);
      expect(find.text('Основы веры · Тема №3'), findsOneWidget);
      expect(find.text('Тема №3'), findsNothing);
      expect(find.textContaining('Первые слова темы'), findsNothing);
      expect(
        tester.widget<AppShareButton>(find.byType(AppShareButton)).text,
        'Тема 3\n\n— Азбука веры',
      );
    },
  );

  testWidgets('последняя тема заканчивается без темы 366', (tester) async {
    await prefs.setString(
      'course_progress_v4',
      jsonEncode({
        'topic': 365,
        'completedTopics': List.generate(364, (i) => i + 1),
      }),
    );
    await pumpReader(
      tester,
      currentTopic: _currentTopic.copyWith(
        id: 'basics-topic-365',
        body: 'Последняя тема',
      ),
    );
    await tester.pumpAndSettle();
    // Листать после последней темы некуда: её засчитывает показ финала.
    final stored =
        jsonDecode(prefs.getString('course_progress_v4')!)
            as Map<String, dynamic>;
    expect(stored['completedTopics'], contains(365));
    expect(progress.readTypes, {CardType.basics});
    final dots = tester.widget<ProgressDots>(find.byType(ProgressDots));
    expect(dots.count, 1);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(cards.requestedTopics, isNot(contains(366)));
    expect(find.text('Последняя тема'), findsOneWidget);
  });

  testWidgets('показывает ошибку, если тема курса не сохранилась', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(courseProgressRepository: _FailingCourseProgressRepository()),
    );
    await tester.pump();
    await tester.pump();
    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось сохранить место чтения'), findsOneWidget);
  });

  testWidgets('keeps the course title visible in the reader header', (
    tester,
  ) async {
    await pumpReader(tester);

    expect(find.text('Основы веры · Тема №3'), findsOneWidget);
  });

  testWidgets('стрелка назад совпадает с размером и цветом действий ридера', (
    tester,
  ) async {
    await pumpReader(tester);

    final icon = tester.widget<Icon>(find.byIcon(CupertinoIcons.arrow_left));
    expect(icon.size, 22);
    expect(icon.color, const Color(0xFF79695E));
    final position = tester.widget<Positioned>(
      find.ancestor(
        of: find.byTooltip('Назад'),
        matching: find.byType(Positioned),
      ),
    );
    expect(position.top, 0);
    expect(position.left, 0);
    expect(position.right, isNull);
  });

  testWidgets('показывает кнопку отправки рядом с закладкой', (tester) async {
    await pumpReader(tester);

    expect(find.byTooltip('Поделиться'), findsOneWidget);
  });

  testWidgets('листается вертикально, как карточки дня', (tester) async {
    await pumpReader(tester);

    expect(
      tester.widget<PageView>(find.byType(PageView)).scrollDirection,
      Axis.vertical,
    );
  });

  testWidgets('uses the reader header instead of the repeated basics badge', (
    tester,
  ) async {
    await pumpReader(tester);

    final badge = tester.widget<AppPillBadge>(find.byType(AppPillBadge));
    expect(badge.label, 'Основы веры · Тема №3');
    expect(badge.background, const Color(0xFFD0E8DE));
    expect(badge.foreground, const Color(0xFF0D4635));
    expect(find.text('Основы'), findsNothing);
  });

  testWidgets('точки слева показывают чанки текущей темы', (tester) async {
    await pumpReader(
      tester,
      currentTopic: _currentTopic.copyWith(
        body: 'Первый абзац.\n\nВторой абзац.',
      ),
    );
    final dots = tester.widget<ProgressDots>(find.byType(ProgressDots));
    expect(dots.count, 2);
    expect(dots.currentIndex, 0);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ProgressDots>(find.byType(ProgressDots)).currentIndex,
      1,
    );
  });

  testWidgets('свайп вниз открывает предыдущую тему, не закрывая читалку', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(showLauncher: true));
    await tester.tap(find.text('Открыть основы'));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CourseReaderScreen),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CourseReaderScreen), findsOneWidget);
    expect(find.text('Тема 2'), findsOneWidget);
  });

  testWidgets('свайп вниз открывает предыдущую тему', (tester) async {
    await pumpReader(tester);

    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(find.text('Тема 2'), findsOneWidget);
    expect(progress.markReadCalls, isEmpty);
  });

  testWidgets('сохраняет тему, на которую юзер перелистнул курс', (
    tester,
  ) async {
    await prefs.setString('course_progress_v4', '{"topic":3}');
    await pumpReader(tester);

    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await tester.pumpAndSettle();

    final saved = await PrefsCourseProgressRepository(prefs).currentTopic();

    expect((saved as Success<int>).value, 2);
  });

  testWidgets('закрытие ожидает сохранения выбранной темы', (tester) async {
    final courseProgress = _DelayedCourseProgressRepository();
    await tester.pumpWidget(
      buildApp(showLauncher: true, courseProgressRepository: courseProgress),
    );
    await tester.tap(find.text('Открыть основы'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();

    expect(find.byType(CourseReaderScreen), findsOneWidget);

    courseProgress.saved.complete(const Success(null));
    await tester.pumpAndSettle();

    expect(find.byType(CourseReaderScreen), findsNothing);
  });

  testWidgets('системный Back ожидает сохранения выбранной темы', (
    tester,
  ) async {
    final courseProgress = _DelayedCourseProgressRepository();
    await tester.pumpWidget(
      buildApp(showLauncher: true, courseProgressRepository: courseProgress),
    );
    await tester.tap(find.text('Открыть основы'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(CourseReaderScreen), findsOneWidget);

    courseProgress.saved.complete(const Success(null));
    await tester.pumpAndSettle();

    expect(find.byType(CourseReaderScreen), findsNothing);
  });

  testWidgets('a failed historical topic can retry without reloading others', (
    tester,
  ) async {
    cards = _CourseCardsRepository(failuresRemaining: {2: 1});
    await pumpReader(tester);

    await tester.drag(find.byType(PageView), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(find.text('Тема недоступна'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    final saved = await PrefsCourseProgressRepository(prefs).currentTopic();
    expect((saved as Success<int>).value, 1);
    final topicOneRequestsBeforeRetry = cards.requestedTopics
        .where((topic) => topic == 1)
        .length;

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Тема 2'), findsOneWidget);
    final savedAfterRetry = await PrefsCourseProgressRepository(
      prefs,
    ).currentTopic();
    expect((savedAfterRetry as Success<int>).value, 2);
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

      await tester.drag(find.byType(PageView), const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(find.text('Тема 1'), findsOneWidget);
      expect(cards.requestedTopics, isEmpty);
      expect(cards.requestedTopics, isNot(contains(0)));
    },
  );
}
