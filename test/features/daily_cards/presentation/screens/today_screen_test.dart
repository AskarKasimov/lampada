import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_event.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/format/russian_date.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/app_pill_badge.dart';
import 'package:lampada/features/bible/domain/entities/daily_verse.dart';
import 'package:lampada/features/bible/presentation/providers/providers.dart';
import 'package:lampada/features/bible/presentation/widgets/verse_of_day_card.dart';
import 'package:lampada/features/daily_cards/domain/course_calendar.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_section.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/card_viewer_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/today_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_content.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_progress_header.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_memory_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_wisdom_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_grid_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_header.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/read_status_checks.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/streak_sheet.dart';
import 'package:lampada/features/day_story/domain/entities/day_story.dart';
import 'package:lampada/features/day_story/domain/repositories/day_story_repository.dart';
import 'package:lampada/features/day_story/presentation/providers/providers.dart';
import 'package:lampada/features/day_story/presentation/screens/day_story_screen.dart';
import 'package:lampada/features/profile/presentation/providers/providers.dart';
import 'package:lampada/features/profile/presentation/services/profile_actions_service.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/domain/repositories/reading_repository.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:lampada/features/reading/presentation/widgets/interpretation_sheet.dart';
import 'package:lampada/features/reading/presentation/widgets/verse_view.dart';
import 'package:lampada/features/reminders/presentation/screens/reminder_permission_screen.dart';
import 'package:lampada/features/shell/presentation/widgets/floating_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';

const _cards = [
  DayCard(
    id: 'quote',
    type: CardType.quote,
    body: 'Первая карточка',
    source: 'Источник 1',
  ),
  DayCard(
    id: 'advice',
    type: CardType.advice,
    body: 'Последняя карточка',
    source: 'Источник 2',
  ),
  DayCard(
    id: 'reading',
    type: CardType.reading,
    body: 'Ин.10:1–9',
    source: 'Азбука веры',
    reference: 'Jn.10:1-9',
  ),
];

const _basics = DayCard(
  id: 'basics',
  type: CardType.basics,
  body: 'Тема 1. О вере и жизни христианина. Далее длинный текст темы.',
  source: 'Азбука веры',
  title: 'О вере и жизни христианина',
);

/// Чтение загружается отдельно от карточек дня, но в UI должно стать
/// страницами их общего просмотрщика.
class _FakeReadingRepository implements ReadingRepository {
  _FakeReadingRepository({DailyReading? reading, this.pending})
    : reading =
          reading ??
          const DailyReading(
            label: 'Ин.10:1–2',
            interpretationAuthor: 'Феофилакт Болгарский',
            verses: [
              Verse(
                number: 1,
                chapter: 10,
                text: 'Первый стих',
                interpretation: 'Толкование первого стиха',
              ),
              Verse(number: 2, chapter: 10, text: 'Второй стих'),
            ],
          );

  final forceRefreshReferences = <String>[];
  final requestedReferences = <String>[];
  final Future<Result<DailyReading>>? pending;
  final DailyReading reading;

  @override
  Future<Result<DailyReading>> getReading(
    String reference, {
    bool forceRefresh = false,
  }) async {
    requestedReferences.add(reference);
    if (forceRefresh) forceRefreshReferences.add(reference);
    return pending == null ? Success(reading) : await pending!;
  }
}

/// Рассказ о дне не должен ходить в сеть из виджет-тестов.
class _FakeDayStoryRepository implements DayStoryRepository {
  @override
  Future<Result<DayStory>> fetch(String url) async =>
      const Success(DayStory(paragraphs: ['Рассказ о памяти дня.']));
}

class _FakeCardsRepository implements DayCardsRepository {
  _FakeCardsRepository({
    this.cards = _cards,
    this.refreshedCards,
    this.failedDates = const {},
    this.pendingDates = const {},
    this.week,
    this.title,
    this.isFast = false,
    this.storyUrl,
  });

  final requested = <String>[];
  final List<DayCard> cards;
  final Map<String, List<DayCard>>? refreshedCards;
  final Set<String> failedDates;
  final Map<String, Future<Result<TodayCards>>> pendingDates;
  final String? week;
  final String? title;
  final bool isFast;
  final String? storyUrl;
  final _cachedCards = <String, List<DayCard>>{};
  final forceRefreshDates = <String>[];

  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    final key = dateKey(date);
    requested.add(key);
    if (pendingDates[key] case final pending?) return pending;
    if (forceRefresh) forceRefreshDates.add(key);
    if (failedDates.contains(key)) {
      return const Failure(
        AppFailure('Контент недоступен', kind: FailureKind.network),
      );
    }
    if (forceRefresh && refreshedCards?[key] != null) {
      _cachedCards[key] = refreshedCards![key]!;
    }
    return Success(
      TodayCards(
        cards: _cachedCards[key] ?? cards,
        week: week,
        title: title,
        isFast: isFast,
        storyUrl: storyUrl,
      ),
    );
  }
}

class _FakeProgressRepository implements DayProgressRepository {
  Set<CardType> _read = {};
  Set<String> _visited = {};
  Map<String, Set<CardType>> _readByDate = {};
  Set<String> _wisdomCompleted = {};

  DayProgress get _current => DayProgress(
    readTypes: _read,
    readTypesByDate: _readByDate,
    visitedDays: _visited,
    wisdomCompletedDays: _wisdomCompleted,
  );

  @override
  Future<Result<DayProgress>> loadToday() async => Success(_current);

  /// Типы, отмеченные именно в ходе теста, отдельно от засеянного прогресса.
  final marked = <CardType>[];

  @override
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) async {
    marked.add(type);
    final day = dateKey(date ?? DateTime.now());
    final read = {..._readByDate[day] ?? const <CardType>{}, type};
    _readByDate = {..._readByDate, day: read};
    if (day == dateKey(DateTime.now())) _read = read;
    if (markVisited) _visited = {..._visited, day};
    return Success(_current);
  }

  @override
  Future<Result<DayProgress>> completeWisdom({
    DateTime? date,
    bool markVisited = true,
  }) async {
    final day = dateKey(date ?? DateTime.now());
    _wisdomCompleted = {..._wisdomCompleted, day};
    if (markVisited) _visited = {..._visited, day};
    return Success(_current);
  }

  Set<CardType> get readTypes => _read;
  Set<String> get visitedDays => _visited;

  void seedRead(Set<CardType> types) {
    _read = types;
    _readByDate = {..._readByDate, dateKey(DateTime.now()): types};
  }

  void seedReadOn(DateTime date, Set<CardType> types) =>
      _readByDate = {..._readByDate, dateKey(date): types};

  void seedVisited(Set<String> days) => _visited = days;

  void seedWisdomCompleted(Set<String> days) => _wisdomCompleted = days;
}

/// Платформенный запрос отзыва в `flutter test` недоступен: считаем вызовы.
class _FakeProfileActions implements ProfileActionsService {
  int reviewRequests = 0;

  @override
  String get reviewLabel => 'Оставить отзыв';

  @override
  Future<void> openUrl(String url) async {}

  @override
  Future<ShareOutcome?> shareApp() async => null;

  @override
  Future<bool> requestReview() async {
    reviewRequests++;
    return true;
  }
}

class _PendingSection extends OpenDaySectionRequestNotifier {
  _PendingSection(this.section);

  final DaySection section;

  @override
  SectionRequest? build() =>
      (section: section, origin: SectionRequestOrigin.notification);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeAnalytics analytics;

  /// По умолчанию считаем, что про напоминания уже спрашивали: их экран
  /// всплывает после закрытия карточки и накрыл бы собой «Сегодня».
  /// Тест про сам запрос ставит флаг обратно.
  setUp(() async {
    analytics = FakeAnalytics();
    SharedPreferences.setMockInitialValues({'flutter.reminders_asked': true});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildApp({
    DayCardsRepository? cardsRepository,
    DayProgressRepository? progressRepository,
    ReadingRepository? readingRepository,
    DayStoryRepository? storyRepository,
    DayCard? courseTopic,
    Future<DayCard?> Function()? courseLoader,
    ProfileActionsService? profileActions,
    DaySection? requestedSection,
    DailyVerse? verse,
    void Function()? onVerseRequested,
  }) => ProviderScope(
    overrides: [
      // Стих дня ходит в сеть за главой Библии; без стиха карточки нет.
      verseOfDayProvider.overrideWith((ref, key) async {
        onVerseRequested?.call();
        return verse ??
            (throw const AppFailure('Нет сети', kind: FailureKind.network));
      }),
      profileActionsServiceProvider.overrideWithValue(
        profileActions ?? _FakeProfileActions(),
      ),
      dayCardsRepositoryProvider.overrideWithValue(
        cardsRepository ?? _FakeCardsRepository(),
      ),
      dayProgressRepositoryProvider.overrideWithValue(
        progressRepository ?? _FakeProgressRepository(),
      ),
      readingRepositoryProvider.overrideWithValue(
        readingRepository ?? _FakeReadingRepository(),
      ),
      dayStoryRepositoryProvider.overrideWithValue(
        storyRepository ?? _FakeDayStoryRepository(),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      analyticsProvider.overrideWithValue(analytics),
      if (courseLoader != null)
        courseTopicProvider.overrideWith((ref) => courseLoader())
      else if (courseTopic != null)
        courseTopicProvider.overrideWith((ref) async => courseTopic),
      if (requestedSection != null)
        openDaySectionRequestProvider.overrideWith(
          () => _PendingSection(requestedSection),
        ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: TodayScreen()),
    ),
  );

  // Прокачиваем вручную и с запасом: переходы маршрутов
  // (просмотрщик открывается как fullscreenDialog) длиннее, чем анимация
  // карточки, а недокачанный переход держит AbsorbPointer и тапы не доходят.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// На главной одна кликабельная запись дневного материала.
  Finder entry(String label) => find.ancestor(
    of: find.textContaining(label),
    matching: find.byType(DayWisdomTile),
  );

  testWidgets('Главная показывает одну кнопку дня и курс без автооткрытия', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(courseTopic: _basics));
    await settle(tester);

    expect(find.byType(CardViewerScreen), findsNothing);
    expect(find.byType(DayWisdomTile), findsOneWidget);
    expect(find.text('Мудрость дня'), findsOneWidget);
    expect(find.byType(CourseProgressHeader), findsOneWidget);
  });

  testWidgets('просьба из приветствия сразу открывает «Мудрость дня»', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(courseTopic: _basics, requestedSection: DaySection.wisdom),
    );
    // Сначала грузится день, потом едет переход в чтение.
    await settle(tester);
    await settle(tester);

    expect(find.byType(CardViewerScreen), findsOneWidget);
    expect(find.text('Первая карточка'), findsOneWidget);
  });

  testWidgets('после закрытия чтение по просьбе не открывается снова', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(courseTopic: _basics, requestedSection: DaySection.wisdom),
    );
    await settle(tester);
    await settle(tester);

    await tester.tap(find.byTooltip('Назад'));
    await settle(tester);
    await settle(tester);

    expect(find.byType(CardViewerScreen), findsNothing);
    expect(find.byType(DayWisdomTile), findsOneWidget);
  });

  testWidgets('просьба ждёт Евангелие, а не открывает чтение без него', (
    tester,
  ) async {
    final pending = Completer<Result<DailyReading>>();
    final reading = _FakeReadingRepository(pending: pending.future);
    await tester.pumpWidget(
      buildApp(
        courseTopic: _basics,
        requestedSection: DaySection.wisdom,
        readingRepository: reading,
      ),
    );
    await settle(tester);
    expect(find.byType(CardViewerScreen), findsNothing);

    pending.complete(Success(reading.reading));
    await settle(tester);

    expect(find.byType(CardViewerScreen), findsOneWidget);
  });

  testWidgets('отдельного блока серии под плитками нет', (tester) async {
    await tester.pumpWidget(buildApp(courseTopic: _basics));
    await settle(tester);

    // Серия живёт в шапке; под «Основами веры» больше ничего нет.
    expect(find.textContaining('подряд'), findsNothing);
    expect(
      find.textContaining('чтобы лампада', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('память дня и «Мудрость дня» стоят в одном ряду', (tester) async {
    await tester.pumpWidget(
      buildApp(
        cardsRepository: _FakeCardsRepository(title: 'Название дня'),
        courseTopic: _basics,
      ),
    );
    await settle(tester);

    final memory = tester.getRect(
      find.descendant(
        of: find.byType(DayMemoryTile),
        matching: find.byType(InkWell),
      ),
    );
    final wisdom = tester.getRect(
      find
          .descendant(
            of: find.byType(DayWisdomTile),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(find.text('Память дня'), findsOneWidget);
    expect(memory.top, wisdom.top);
    expect(memory.height, wisdom.height);
    expect(memory.left, 16);
    expect(wisdom.right, 800 - 16);
    expect(wisdom.left - memory.right, 12);
  });

  testWidgets('крупная плитка дня открывает чтение по нажатию', (tester) async {
    await tester.pumpWidget(
      buildApp(
        cardsRepository: _FakeCardsRepository(title: 'Название дня'),
        courseTopic: _basics,
      ),
    );
    await settle(tester);

    final button = find.descendant(
      of: find.byType(DayWisdomTile),
      matching: find.byType(InkWell),
    );
    final calendar = find.text('Мудрость дня');
    expect(button, findsOneWidget);
    expect(calendar, findsOneWidget);
    expect(
      tester.getSize(button).height,
      greaterThanOrEqualTo(HomeGridTile.minHeight),
    );
    expect(tester.getRect(button).right, 800 - 16);

    await tester.tap(calendar);
    await settle(tester);
    expect(find.text('Первая карточка'), findsOneWidget);
  });

  testWidgets(
    'день загружает Евангелие до открытия и сразу показывает все точки',
    (tester) async {
      final pending = Completer<Result<DailyReading>>();
      final reading = _FakeReadingRepository(pending: pending.future);
      await tester.pumpWidget(
        buildApp(readingRepository: reading, courseTopic: _basics),
      );
      await settle(tester);

      expect(reading.requestedReferences, ['Jn.10:1-9']);
      await tester.tap(find.text('Мудрость дня'));
      await settle(tester);
      expect(find.byType(CardViewerScreen), findsNothing);

      pending.complete(Success(reading.reading));
      await settle(tester);
      await tester.tap(find.text('Мудрость дня'));
      await settle(tester);
      expect(find.text('Первая карточка'), findsOneWidget);
      expect(tester.widget<ProgressDots>(find.byType(ProgressDots)).count, 5);
      await settle(tester);
      expect(tester.widget<ProgressDots>(find.byType(ProgressDots)).count, 5);
      expect(reading.requestedReferences, ['Jn.10:1-9']);
    },
  );

  testWidgets(
    'ошибка предварительной загрузки не блокирует остальные материалы',
    (tester) async {
      final reading = _FakeReadingRepository(
        pending: Future.value(
          const Failure(AppFailure('Нет сети', kind: FailureKind.network)),
        ),
      );
      await tester.pumpWidget(
        buildApp(readingRepository: reading, courseTopic: _basics),
      );
      await settle(tester);
      await tester.pump(const Duration(seconds: 30));
      expect(reading.requestedReferences, ['Jn.10:1-9']);

      await tester.tap(find.text('Мудрость дня'));
      await settle(tester);
      expect(find.text('Первая карточка'), findsOneWidget);
      await tester.drag(find.byType(PageView).last, const Offset(0, -600));
      await settle(tester);
      await tester.drag(find.byType(PageView).last, const Offset(0, -600));
      await settle(tester);
      expect(find.text('Евангелие дня сейчас недоступно'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    },
  );

  testWidgets('Мудрость дня начинает с первого непрочитанного материала', (
    tester,
  ) async {
    final progress = _FakeProgressRepository()
      ..seedRead({CardType.quote, CardType.advice});
    await tester.pumpWidget(buildApp(progressRepository: progress));
    await settle(tester);

    await tester.tap(find.text('Мудрость дня'));
    await settle(tester);
    expect(find.text('Первый стих'), findsOneWidget);
    expect(find.text('Первая карточка'), findsNothing);
  });

  testWidgets('прочитанная Мудрость дня повторно открывается с начала', (
    tester,
  ) async {
    final progress = _FakeProgressRepository()
      ..seedRead({CardType.quote, CardType.advice, CardType.reading});
    await tester.pumpWidget(buildApp(progressRepository: progress));
    await settle(tester);

    await tester.tap(find.text('Мудрость дня'));
    await settle(tester);
    expect(find.text('Первая карточка'), findsOneWidget);
  });

  testWidgets('день только с Евангелием открывает первый стих', (tester) async {
    await tester.pumpWidget(
      buildApp(cardsRepository: _FakeCardsRepository(cards: [_cards.last])),
    );
    await settle(tester);

    expect(find.byType(DayWisdomTile), findsOneWidget);
    await tester.tap(find.text('Мудрость дня'));
    await settle(tester);
    expect(find.text('Первый стих'), findsOneWidget);
  });

  testWidgets('день без материалов не показывает кнопку чтения', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        cardsRepository: _FakeCardsRepository(cards: const []),
        courseTopic: _basics,
      ),
    );
    await settle(tester);

    expect(find.text('Мудрость дня'), findsNothing);
    expect(find.text('За этот день карточек нет'), findsOneWidget);
    expect(find.byType(CourseProgressHeader), findsOneWidget);
  });

  testWidgets('курс доступен при ошибке загрузки выбранного дня', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        cardsRepository: _FakeCardsRepository(
          failedDates: {dateKey(DateTime.now())},
        ),
        courseTopic: _basics,
      ),
    );
    await settle(tester);

    expect(find.textContaining('не загружены'), findsOneWidget);
    expect(find.byType(CourseProgressHeader), findsOneWidget);
    // Экран ошибки перестраивается, но показ считается одним.
    expect(analytics.single('content_load_failed'), {
      'content': 'day',
      'kind': 'network',
    });
  });

  testWidgets('курс доступен пока материал выбранного дня загружается', (
    tester,
  ) async {
    final pending = Completer<Result<TodayCards>>();
    await tester.pumpWidget(
      buildApp(
        cardsRepository: _FakeCardsRepository(
          pendingDates: {dateKey(DateTime.now()): pending.future},
        ),
        courseTopic: _basics,
      ),
    );
    await tester.pump();

    expect(find.text('Мудрость дня'), findsNothing);
    expect(find.byType(CourseProgressHeader), findsOneWidget);
    pending.complete(const Success(TodayCards(cards: [])));
    await settle(tester);
  });

  testWidgets('на плитке курса нет справки и полосы прогресса', (tester) async {
    await tester.pumpWidget(buildApp(courseTopic: _basics));
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(CourseProgressHeader),
        matching: find.byTooltip('О курсе'),
      ),
      findsNothing,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('ошибка курса повторяется независимо от материала дня', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      buildApp(
        courseLoader: () async {
          attempts++;
          return attempts == 1 ? null : _basics;
        },
      ),
    );
    await settle(tester);

    expect(find.text('Мудрость дня'), findsOneWidget);
    expect(find.text('Не удалось загрузить «Основы веры»'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await settle(tester);
    expect(find.byType(CourseProgressHeader), findsOneWidget);
  });

  for (final readToday in [false, true]) {
    testWidgets(
      'галочки курса на главной отражают чтение сегодня: $readToday',
      (tester) async {
        final progress = _FakeProgressRepository();
        if (readToday) progress.seedRead({CardType.basics});
        await tester.pumpWidget(
          buildApp(progressRepository: progress, courseTopic: _basics),
        );
        await settle(tester);

        final checks = find.descendant(
          of: find.byType(CourseProgressHeader),
          matching: find.byIcon(CupertinoIcons.checkmark_alt),
        );
        expect(checks, findsNWidgets(2));
        final colors = AppColorsExtension.of(
          tester.element(find.byType(CourseProgressHeader)),
        );
        for (final icon in tester.widgetList<Icon>(checks)) {
          expect(
            icon.color,
            readToday
                ? colors.accent
                : colors.textTertiary.withValues(alpha: 0.4),
          );
        }
      },
    );
  }

  group('вкладка «Сегодня»', () {
    testWidgets('без памяти дня «Мудрость» во всю ширину, как курс', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(courseTopic: _basics));
      await settle(tester);

      final screen = tester.getRect(find.byType(TodayScreen));
      Rect tile(Type type) => tester.getRect(
        find
            .descendant(of: find.byType(type), matching: find.byType(InkWell))
            .first,
      );
      final wisdom = tile(DayWisdomTile);
      final course = tile(CourseProgressHeader);
      expect(wisdom.left, screen.left + 16);
      expect(wisdom.right, screen.right - 16);
      expect(course.left, wisdom.left);
      expect(course.right, wisdom.right);
      expect(course.top, greaterThan(wisdom.bottom));
      expect(
        find.descendant(
          of: find.byType(DayWisdomTile),
          matching: find.byIcon(CupertinoIcons.checkmark_alt),
        ),
        findsNWidgets(2),
      );
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('плитки дня одной высоты в ряду, масштаб $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(393, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          buildApp(
            courseTopic: _basics,
            cardsRepository: _FakeCardsRepository(
              title: 'Мц. Христи́ны Тирской',
              isFast: true,
              storyUrl: 'https://azbyka.ru/days/sv-hristina',
            ),
          ),
        );
        await settle(tester);

        Rect tile(Type type) => tester.getRect(
          find
              .descendant(of: find.byType(type), matching: find.byType(InkWell))
              .first,
        );
        final memory = tile(DayMemoryTile);
        final wisdom = tile(DayWisdomTile);
        final course = tile(CourseProgressHeader);
        // Плитки дня стоят рядом и одной высоты при любом масштабе текста,
        // курс ниже, в разделе «Планы».
        expect(memory.height, wisdom.height);
        expect(memory.top, wisdom.top);
        expect(memory.height, greaterThanOrEqualTo(HomeGridTile.minHeight));
        expect(course.top, greaterThan(wisdom.bottom));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('«Стих дня» стоит над плитками дня', (tester) async {
      await tester.pumpWidget(
        buildApp(
          courseTopic: _basics,
          verse: const DailyVerse(
            book: 'Jn',
            chapter: 3,
            verse: 16,
            text: 'Ибо так возлюбил Бог мир.',
          ),
          cardsRepository: _FakeCardsRepository(
            title: 'Мц. Христи́ны Тирской',
            storyUrl: 'https://azbyka.ru/days/sv-hristina',
          ),
        ),
      );
      await settle(tester);

      final verse = tester.getRect(find.byType(VerseOfDayCard));
      expect(find.text('Ин. 3:16'), findsOneWidget);
      expect(
        verse.top,
        greaterThan(tester.getRect(find.byType(HomeHeader)).bottom - 1),
      );
      expect(
        verse.bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(DayMemoryTile)).top),
      );
    });

    testWidgets('обновление жестом перезапрашивает стих дня', (tester) async {
      var requests = 0;
      await tester.pumpWidget(buildApp(onVerseRequested: () => requests++));
      await settle(tester);
      expect(requests, 1);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await settle(tester);

      expect(requests, 2);
    });

    testWidgets('день отделён от планов заголовками разделов', (tester) async {
      await tester.pumpWidget(
        buildApp(
          courseTopic: _basics,
          cardsRepository: _FakeCardsRepository(
            title: 'Мц. Христи́ны Тирской',
            storyUrl: 'https://azbyka.ru/days/sv-hristina',
          ),
        ),
      );
      await settle(tester);

      final today = tester.getRect(find.text('Сегодня'));
      final date = tester.getRect(
        find.text(russianDayMonth(DateTime.now()), findRichText: true),
      );
      final plans = tester.getRect(find.text('Планы'));
      Rect tile(Type type) => tester.getRect(
        find
            .descendant(of: find.byType(type), matching: find.byType(InkWell))
            .first,
      );
      expect(date.bottom, lessThanOrEqualTo(today.top));
      expect(today.bottom, lessThanOrEqualTo(tile(DayMemoryTile).top));
      expect(plans.top, greaterThan(tile(DayWisdomTile).bottom));
      expect(plans.bottom, lessThanOrEqualTo(tile(CourseProgressHeader).top));
      expect(find.text('в своём темпе'), findsNothing);
      // Перед планами заметный зазор, чтобы разделы не слипались.
      expect(plans.top - tile(DayWisdomTile).bottom, greaterThan(16));
    });

    testWidgets('седмица не показывается, память и пост остаются', (
      tester,
    ) async {
      // Строка седмицы почти ничего не сообщала, а шапку перегружала.
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet());
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(
            week: 'Седмица 10-я по Пятидесятнице',
            title: 'Мц. Христи́ны Тирской',
            isFast: true,
          ),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      expect(find.textContaining('СЕДМИЦА'), findsNothing);
      expect(find.textContaining('Седмица'), findsNothing);
      final headerBottom = tester.getBottomLeft(find.byType(HomeHeader)).dy;

      // Память остаётся плиткой дня, пост отмечен в заголовке «Сегодня».
      final nameTop = tester.getTopLeft(find.text('Память дня')).dy;
      expect(nameTop, greaterThan(headerBottom));
      final today = tester.getRect(find.text('Сегодня'));
      final fast = find.textContaining('Постный день', findRichText: true);
      expect(fast, findsOneWidget);
      expect(tester.getRect(fast).bottom, lessThanOrEqualTo(today.top));
    });

    testWidgets('напоминание о святом открывает рассказ дня', (tester) async {
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(
            title: 'Мц. Христи́ны Тирской',
            storyUrl: 'https://azbyka.ru/days/sv-hristina',
          ),
          requestedSection: DaySection.story,
        ),
      );
      await settle(tester);
      await settle(tester);

      expect(find.byType(DayStoryScreen), findsOneWidget);
      expect(analytics.single('story_opened')['source'], 'notification');
    });

    testWidgets('открытый рассказ отмечается прочитанным за свой день', (
      tester,
    ) async {
      // Иначе напоминание о святом пришло бы тому, кто уже прочитал.
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(
            title: 'Мц. Христи́ны Тирской',
            storyUrl: 'https://azbyka.ru/days/sv-hristina',
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.byType(DayMemoryTile));
      await settle(tester);

      expect(
        prefs.getStringList('story_read_days'),
        contains(dateKey(DateTime.now())),
      );
      // После возврата из рассказа память дня отмечена галочками.
      await tester.tap(find.byTooltip('Закрыть рассказ'));
      await settle(tester);
      expect(
        tester
            .widget<ReadStatusChecks>(
              find.descendant(
                of: find.byType(DayMemoryTile),
                matching: find.byType(ReadStatusChecks),
              ),
            )
            .isUnread,
        isFalse,
      );
    });

    testWidgets('напоминание о курсе открывает тему «Основ веры»', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(courseTopic: _basics, requestedSection: DaySection.course),
      );
      await settle(tester);
      await settle(tester);

      expect(find.byType(CourseReaderScreen), findsOneWidget);
      expect(analytics.single('course_opened')['source'], 'notification');
    });

    testWidgets('тап по памяти дня со ссылкой открывает рассказ', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet());
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(
            title: 'Мц. Христи́ны Тирской',
            storyUrl: 'https://azbyka.ru/days/sv-hristina',
          ),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      await tester.tap(find.byType(DayMemoryTile));
      await settle(tester);

      expect(find.byType(DayStoryScreen), findsOneWidget);
      // Рассказ открывается обложкой с названием, текст идёт следующими
      // страницами листалки.
      expect(
        find.descendant(
          of: find.byType(DayStoryScreen),
          matching: find.text('Мц. Христи́ны Тирской'),
        ),
        findsWidgets,
      );
    });

    testWidgets('память дня без ссылки не открывает рассказ', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet());
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(title: 'Мц. Христи́ны Тирской'),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      await tester.tap(find.byType(DayMemoryTile));
      await settle(tester);
      expect(find.byType(DayStoryScreen), findsNothing);
    });

    testWidgets('показывает шапку и одну кнопку дня', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.byType(DayWisdomTile), findsOneWidget);
      expect(entry('Мудрость дня'), findsOneWidget);
      expect(entry('ЗАКЛАДКИ'), findsNothing);
      expect(find.text('Копилка смыслов'), findsNothing);
    });

    testWidgets('шапка отделена от плиток, а список от навбара запасом', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet());
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      final headerBottom = tester.getBottomLeft(find.text('Сегодня')).dy;
      final firstTop = tester.getTopLeft(find.byType(DayWisdomTile).first).dy;
      expect(firstTop - headerBottom, greaterThanOrEqualTo(4));

      final list = tester.widget<ListView>(find.byType(ListView));
      final padding = list.padding!.resolve(TextDirection.ltr);
      expect(padding.top, 0);
      expect(padding.bottom, kFloatingNavInset + 32);
    });

    testWidgets('pull-to-refresh обновляет все источники контента дня', (
      tester,
    ) async {
      const refreshed = DayCard(
        id: 'quote-refreshed',
        type: CardType.quote,
        body: 'Свежая карточка',
        source: 'Источник 1',
      );
      final today = dateKey(DateTime.now());
      final cards = _FakeCardsRepository(
        cards: [..._cards, _basics],
        refreshedCards: {
          today: [refreshed, ..._cards.skip(1), _basics],
        },
      );
      final reading = _FakeReadingRepository();
      final progress = _FakeProgressRepository()
        ..seedRead([..._cards, _basics].map((card) => card.type).toSet());
      await tester.pumpWidget(
        buildApp(
          cardsRepository: cards,
          progressRepository: progress,
          readingRepository: reading,
        ),
      );
      await settle(tester);
      cards.forceRefreshDates.clear();

      expect(find.text('Мудрость дня'), findsOneWidget);
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      expect(find.text('Свежая карточка'), findsOneWidget);
      expect(
        cards.forceRefreshDates,
        containsAll([today, dateKey(dateForCourseTopic(1))]),
      );
      expect(reading.forceRefreshReferences, ['Jn.10:1-9']);
    });

    testWidgets('прочитанная Мудрость дня остаётся доступной', (tester) async {
      // Раньше пройденный день встречал экраном завершения с «Пройти снова»,
      // и чтобы перечитать одну карточку, надо было запускать день заново.
      // День пройден целиком, но кнопка остаётся доступной для перечтения.
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      expect(find.byType(DayWisdomTile), findsOneWidget);
      expect(entry('Мудрость дня'), findsOneWidget);
      expect(find.text('Пройти снова'), findsNothing);
    });
  });

  group('полноэкранный просмотр', () {
    testWidgets('в просмотрщике карточки и стихи идут подряд', (tester) async {
      // Отдельной страницы завершения нет: она объявляла день оконченным,
      // хотя Евангелие и курс остаются на сегодня.
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      final pageView = tester.widget<PageView>(
        find.descendant(
          of: find.byType(CardViewerScreen),
          matching: find.byType(PageView),
        ),
      );
      expect(pageView.childrenDelegate.estimatedChildCount, 5);
      expect(pageView.scrollDirection, Axis.vertical);
    });

    testWidgets('длинная карточка открывает полноэкранный текст', (
      tester,
    ) async {
      final longCard = DayCard(
        id: 'long-advice',
        type: CardType.advice,
        body: List.filled(400, 'Длинный текст карточки').join(' '),
        source: 'Тестовый источник',
      );
      final progress = _FakeProgressRepository()..seedRead({CardType.quote});
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(
            cards: [_cards.first, longCard, _cards.last],
          ),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      final preview = '${longCard.body.substring(0, 150)}…';
      expect(find.text(preview), findsOneWidget);
      expect(find.text(longCard.body), findsNothing);
      final fullscreen = find.byTooltip('Открыть полный текст');
      final bookmark = find.byTooltip('Сохранить в копилку');
      final share = find.byTooltip('Поделиться');
      expect(fullscreen, findsOneWidget);
      expect(
        tester.getTopLeft(fullscreen).dy,
        lessThan(tester.getTopLeft(bookmark).dy),
      );
      expect(
        tester.getTopLeft(bookmark).dy,
        lessThan(tester.getTopLeft(share).dy),
      );
      expect(tester.getSize(fullscreen), const Size(56, 56));
      await tester.tap(fullscreen);
      await settle(tester);

      expect(find.text(longCard.body), findsOneWidget);
    });

    testWidgets('читалка не оставляет боковые safe-area для рельсов', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      final safeArea = tester.widget<SafeArea>(
        find.descendant(
          of: find.byType(CardViewerScreen),
          matching: find.byType(SafeArea),
        ),
      );
      expect(safeArea.left, isFalse);
      expect(safeArea.right, isFalse);
      expect(tester.getTopLeft(find.byType(ProgressDots)).dx, 12);
      expect(tester.getTopLeft(find.byType(PageView)).dx, 29);
      expect(tester.getTopRight(find.byTooltip('Поделиться')).dx, 788);
    });

    testWidgets('тап по блоку открывает карточку без таб-бара', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsOneWidget);
      expect(find.byType(CourseReaderScreen), findsNothing);
      // Просмотрщик — маршрут поверх шелла, навигации в нём нет.
      expect(
        find.descendant(
          of: find.byType(CardViewerScreen),
          matching: find.byType(FloatingNavBar),
        ),
        findsNothing,
      );
    });

    testWidgets('бейдж карточки закреплён в шапке просмотрщика', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      final badge = find.descendant(
        of: find.byType(CardViewerScreen),
        matching: find.byType(AppPillBadge),
      );
      expect(badge, findsOneWidget);
      expect(
        find.ancestor(of: badge, matching: find.byType(CardContent)),
        findsNothing,
      );
    });

    testWidgets('крестик закрывает просмотрщик и возвращает к блокам', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.byType(DayWisdomTile), findsOneWidget);
    });

    testWidgets('открытая карточка сразу засчитывается прочитанной', (
      tester,
    ) async {
      final progress = _FakeProgressRepository();
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      expect(progress.readTypes, contains(CardType.quote));
      expect(progress.readTypes, isNot(contains(CardType.advice)));
    });
  });

  group('Евангелие как карточка дня', () {
    testWidgets('вмещающийся длинный стих не требует полного экрана', (
      tester,
    ) async {
      final verseText = List.filled(15, 'Длинный стих').join(' ');
      final reading = DailyReading(
        label: 'Мк.12:1',
        verses: [Verse(number: 1, chapter: 12, text: verseText)],
      );
      await tester.pumpWidget(
        buildApp(
          readingRepository: _FakeReadingRepository(reading: reading),
          progressRepository: _FakeProgressRepository()
            ..seedRead({CardType.quote, CardType.advice}),
        ),
      );
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      expect(find.text(verseText), findsOneWidget);
      expect(find.byTooltip('Открыть полный текст'), findsNothing);
    });

    testWidgets('тап по блоку открывает общий просмотрщик', (tester) async {
      await tester.pumpWidget(
        buildApp(
          progressRepository: _FakeProgressRepository()
            ..seedRead({CardType.quote, CardType.advice}),
        ),
      );
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsOneWidget);
      final pageView = tester.widget<PageView>(
        find.descendant(
          of: find.byType(CardViewerScreen),
          matching: find.byType(PageView),
        ),
      );
      expect(pageView.childrenDelegate.estimatedChildCount, 5);
      expect(find.text('Первый стих'), findsOneWidget);
      expect(find.byType(VerseInterpretationButton), findsOneWidget);
      await tester.tap(find.byType(VerseInterpretationButton));
      await settle(tester);
      expect(find.byType(InterpretationSheet), findsOneWidget);
    });

    testWidgets('открытие карточки засчитывает Евангелие прочитанным', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      expect(progress.readTypes, contains(CardType.reading));
    });
  });

  group('шапка и шторка серии', () {
    testWidgets('шапка без приветствия показывает серию', (tester) async {
      final today = DateTime.now();
      final progress = _FakeProgressRepository()
        ..seedVisited({
          dateKey(today),
          dateKey(DateTime(today.year, today.month, today.day - 1)),
        });

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      expect(find.text('Сегодня'), findsOneWidget);
      expect(find.textContaining('Добр'), findsNothing);
      expect(find.bySemanticsLabel('Лампадка: 2 дня подряд'), findsOneWidget);
    });

    testWidgets('тап по лампаде открывает шторку серии', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedVisited({dateKey(DateTime.now())});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.tap(find.bySemanticsLabel('Лампадка: 1 день подряд'));
      await settle(tester);

      expect(find.byType(StreakSheet), findsOneWidget);
      expect(
        find.text('Лампадка помогает сделать чтение ежедневной привычкой'),
        findsOneWidget,
      );
      expect(find.text('Лучшая: 1'), findsOneWidget);
      expect(find.text('Прочитано глав: 0'), findsOneWidget);
    });

    testWidgets('календаря на главной нет', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      expect(
        find.descendant(
          of: find.byType(TodayScreen),
          matching: find.byType(PageView),
        ),
        findsNothing,
      );
      final today = DateTime.now();
      const months = [
        'Январь',
        'Февраль',
        'Март',
        'Апрель',
        'Май',
        'Июнь',
        'Июль',
        'Август',
        'Сентябрь',
        'Октябрь',
        'Ноябрь',
        'Декабрь',
      ];
      expect(
        find.textContaining('${months[today.month - 1]} ${today.year}'),
        findsNothing,
      );
      // Кнопки «Сегодня» из прежнего календаря нет; «Сегодня» на главной
      // только заголовок раздела.
      expect(find.widgetWithText(TextButton, 'Сегодня'), findsNothing);
    });

    testWidgets('свайп по содержимому не переключает день', (tester) async {
      final repo = _FakeCardsRepository();
      await tester.pumpWidget(buildApp(cardsRepository: repo));
      await settle(tester);

      await tester.fling(
        find.byType(DayWisdomTile),
        const Offset(-400, 0),
        1000,
      );
      await settle(tester);
      await tester.fling(
        find.byType(DayWisdomTile),
        const Offset(400, 0),
        1000,
      );
      await settle(tester);

      // Соседние дни больше не предзагружаются: открыть их нельзя.
      final today = DateTime.now();
      for (final offset in [-1, 1]) {
        expect(
          repo.requested,
          isNot(
            contains(
              dateKey(DateTime(today.year, today.month, today.day + offset)),
            ),
          ),
        );
      }
      expect(find.byType(DayWisdomTile), findsOneWidget);
    });
  });

  group('конец сессии', () {
    testWidgets('просмотрщик закрывается стрелкой «Назад» в любой момент', (
      tester,
    ) async {
      // Экран итога стоит только в конце листалки; уйти раньше можно
      // без него, и прочитанное при этом сохраняется.
      await tester.pumpWidget(buildApp());
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      final pageView = find.descendant(
        of: find.byType(CardViewerScreen),
        matching: find.byType(PageView),
      );
      for (var i = 1; i < 5; i++) {
        await tester.fling(pageView, const Offset(-400, 0), 1000);
        await settle(tester);
      }

      await tester.tap(find.byTooltip('Назад'));
      await settle(tester);

      expect(find.byType(CardViewerScreen, skipOffstage: false), findsNothing);
      expect(find.byType(DayWisdomTile), findsWidgets);
    });
  });

  group('запрос напоминаний', () {
    /// Разрешение спрашиваем ПОСЛЕ первой карточки: iOS показывает системный
    /// запрос один раз за установку, и потратить его на холодный старт значит
    /// с большой вероятностью получить отказ навсегда.
    Future<void> pumpFresh(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(buildApp());
      await settle(tester);
    }

    testWidgets('до первой карточки не спрашиваем', (tester) async {
      await pumpFresh(tester);

      expect(find.text('Мудрость дня'), findsOneWidget);
      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.byType(ReminderPermissionScreen), findsNothing);
    });

    testWidgets('после закрытия первой карточки спрашиваем', (tester) async {
      await pumpFresh(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
      await settle(tester);

      expect(find.byType(ReminderPermissionScreen), findsOneWidget);
      expect(find.textContaining('на 36% чаще'), findsOneWidget);
    });

    testWidgets('спрашиваем один раз, даже после отказа', (tester) async {
      await pumpFresh(tester);
      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
      await settle(tester);

      await tester.tap(find.text('Не сейчас'));
      await settle(tester);
      expect(find.byType(ReminderPermissionScreen), findsNothing);

      // Открыли и закрыли ещё одну карточку — второй раз не спрашиваем:
      // системное разрешение всё равно показывается только однажды.
      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
      await settle(tester);

      expect(find.byType(ReminderPermissionScreen), findsNothing);
    });
  });

  group('запрос оценки', () {
    /// Листает «Мудрость дня» до экрана итога и ждёт, пока «Готово» станет
    /// нажимаемой: итог раскрывается анимацией.
    Future<void> reachSummary(WidgetTester tester) async {
      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      for (var i = 0; i < 8 && find.text('Готово').evaluate().isEmpty; i++) {
        await tester.drag(
          find.descendant(
            of: find.byType(CardViewerScreen),
            matching: find.byType(PageView),
          ),
          const Offset(0, -600),
        );
        await settle(tester);
      }
      // Анимации итога идут цепочкой, каждой нужен свой кадр.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.text('Готово').hitTestable(), findsOneWidget);
    }

    group('аналитика', () {
      testWidgets('тап по плитке пишет открытие «Мудрости»', (tester) async {
        await tester.pumpWidget(buildApp());
        await settle(tester);

        await tester.tap(entry('Мудрость дня'));
        await settle(tester);

        final opened = analytics.single('wisdom_opened');
        expect(opened['source'], 'tile');
        expect(opened['day_offset'], 0);
        expect(opened['already_completed'], false);
      });

      testWidgets('выход до итога пишет глубину чтения', (tester) async {
        await tester.pumpWidget(buildApp());
        await settle(tester);
        await tester.tap(entry('Мудрость дня'));
        await settle(tester);

        await tester.tap(find.byTooltip('Назад'));
        await settle(tester);

        final closed = analytics.single('wisdom_closed');
        expect(closed['pages_seen'], 1);
        expect(closed['completed'], false);
        expect(closed['pages_total'], greaterThan(1));
      });

      testWidgets('первый итог дня пишет завершение и зажжённую лампаду', (
        tester,
      ) async {
        await tester.pumpWidget(buildApp());
        await settle(tester);

        await reachSummary(tester);

        final completed = analytics.single('wisdom_completed');
        expect(completed['counts_streak'], true);
        expect(completed['lifetime_days'], 1);
        expect(analytics.single('lamp_lit'), {
          'source': 'wisdom',
          'streak': 1,
          'restarted': true,
        });
      });

      testWidgets('повторный итог ведёт в главу и завершением не считается', (
        tester,
      ) async {
        final progress = _FakeProgressRepository()
          ..seedWisdomCompleted({dateKey(DateTime.now())});
        await tester.pumpWidget(buildApp(progressRepository: progress));
        await settle(tester);
        await tester.tap(entry('Мудрость дня'));
        await settle(tester);

        for (var i = 0; i < 8; i++) {
          final reader = find.descendant(
            of: find.byType(CardViewerScreen),
            matching: find.byType(PageView),
          );
          if (reader.evaluate().isEmpty) break;
          await tester.drag(reader, const Offset(0, -600));
          await settle(tester);
        }

        expect(analytics.names, isNot(contains('wisdom_completed')));
        expect(analytics.single('summary_chapter_opened'), {'auto': true});
      });
    });

    testWidgets('после первого итога просим оценку, когда юзер ушёл с него', (
      tester,
    ) async {
      final actions = _FakeProfileActions();
      await tester.pumpWidget(buildApp(profileActions: actions));
      await settle(tester);

      await reachSummary(tester);
      // Пока юзер смотрит на лампаду, системный диалог не перебивает итог.
      expect(actions.reviewRequests, 0);

      await tester.tap(find.text('Готово'));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
      expect(actions.reviewRequests, 1);
    });

    testWidgets('после повторного итога оценку не просим', (tester) async {
      final actions = _FakeProfileActions();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final progress = _FakeProgressRepository()
        ..seedWisdomCompleted({dateKey(yesterday)});
      await tester.pumpWidget(
        buildApp(progressRepository: progress, profileActions: actions),
      );
      await settle(tester);

      await reachSummary(tester);
      await tester.tap(find.text('Готово'));
      await settle(tester);

      expect(actions.reviewRequests, 0);
    });

    testWidgets('ушли до итога: оценку не просим', (tester) async {
      final actions = _FakeProfileActions();
      await tester.pumpWidget(buildApp(profileActions: actions));
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      await tester.tap(find.byTooltip('Назад'));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
      expect(actions.reviewRequests, 0);
    });
  });
}
