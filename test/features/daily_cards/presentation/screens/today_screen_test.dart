import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/app_pill_badge.dart';
import 'package:lampada/core/widgets/brand_loading_view.dart';
import 'package:lampada/features/daily_cards/domain/course_calendar.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/card_viewer_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/today_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_content.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_progress_header.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_entry_row.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_name_header.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_wisdom_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/progress_dots.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/today_offline_view.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/week_strip.dart';
import 'package:lampada/features/day_story/domain/entities/day_story.dart';
import 'package:lampada/features/day_story/domain/repositories/day_story_repository.dart';
import 'package:lampada/features/day_story/presentation/providers/providers.dart';
import 'package:lampada/features/day_story/presentation/screens/day_story_screen.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/domain/repositories/reading_repository.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:lampada/features/reading/presentation/widgets/interpretation_sheet.dart';
import 'package:lampada/features/reading/presentation/widgets/verse_view.dart';
import 'package:lampada/features/reminders/presentation/screens/reminder_permission_screen.dart';
import 'package:lampada/features/shell/presentation/widgets/floating_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  DayProgress get _current => DayProgress(
    readTypes: _read,
    readTypesByDate: _readByDate,
    visitedDays: _visited,
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

  Set<CardType> get readTypes => _read;
  Set<String> get visitedDays => _visited;

  void seedRead(Set<CardType> types) {
    _read = types;
    _readByDate = {..._readByDate, dateKey(DateTime.now()): types};
  }

  void seedReadOn(DateTime date, Set<CardType> types) =>
      _readByDate = {..._readByDate, dateKey(date): types};

  void seedVisited(Set<String> days) => _visited = days;
}

class _SelectedDateNotifier extends SelectedDateNotifier {
  _SelectedDateNotifier(this.date);

  final DateTime date;

  @override
  DateTime build() => date;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  /// По умолчанию считаем, что про напоминания уже спрашивали: их экран
  /// всплывает после закрытия карточки и накрыл бы собой «Сегодня».
  /// Тест про сам запрос ставит флаг обратно.
  setUp(() async {
    SharedPreferences.setMockInitialValues({'flutter.reminders_asked': true});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildApp({
    DayCardsRepository? cardsRepository,
    DayProgressRepository? progressRepository,
    ReadingRepository? readingRepository,
    DateTime? selectedDate,
    DayCard? courseTopic,
    Future<DayCard?> Function()? courseLoader,
  }) => ProviderScope(
    overrides: [
      dayCardsRepositoryProvider.overrideWithValue(
        cardsRepository ?? _FakeCardsRepository(),
      ),
      dayProgressRepositoryProvider.overrideWithValue(
        progressRepository ?? _FakeProgressRepository(),
      ),
      readingRepositoryProvider.overrideWithValue(
        readingRepository ?? _FakeReadingRepository(),
      ),
      dayStoryRepositoryProvider.overrideWithValue(_FakeDayStoryRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (courseLoader != null)
        courseTopicProvider.overrideWith((ref) => courseLoader())
      else if (courseTopic != null)
        courseTopicProvider.overrideWith((ref) async => courseTopic),
      if (selectedDate != null)
        selectedDateProvider.overrideWith(
          () => _SelectedDateNotifier(selectedDate),
        ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: TodayScreen()),
    ),
  );

  // StreakFlame крутится бесконечно (repeat(reverse: true)) — pumpAndSettle
  // никогда не осядет. Прокачиваем вручную, и с запасом: переходы маршрутов
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

  testWidgets('Домой показывает одну кнопку дня и курс без автооткрытия', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(courseTopic: _basics));
    await settle(tester);

    expect(find.byType(CardViewerScreen), findsNothing);
    expect(find.byType(DayWisdomTile), findsOneWidget);
    expect(find.text('Мудрость дня'), findsOneWidget);
    expect(find.byType(CourseProgressHeader), findsOneWidget);
  });

  testWidgets('крупная кнопка дня открывает чтение по нажатию на календарь', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        cardsRepository: _FakeCardsRepository(title: 'Название дня'),
        courseTopic: _basics,
      ),
    );
    await settle(tester);

    final button = find.ancestor(
      of: find.text('Мудрость дня'),
      matching: find.byType(InkWell),
    );
    final calendar = find.descendant(
      of: button,
      matching: find.byIcon(CupertinoIcons.calendar),
    );
    expect(calendar, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(80));
    expect(tester.getRect(button).left, 0);
    expect(tester.getRect(button).right, 800);
    // Остаётся только разделитель после названия дня, над кнопкой.
    expect(find.byType(DayEntryDivider), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byType(DayEntryDivider)).dy,
      lessThanOrEqualTo(tester.getTopLeft(button).dy),
    );

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

  testWidgets('справка курса на главной объясняет вход в чтение', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(courseTopic: _basics));
    await settle(tester);
    final heading = find.text('Планы');
    final info = find.byTooltip('О курсе');
    expect(heading, findsOneWidget);
    expect(tester.getTopLeft(heading).dx, 16);
    expect(tester.getRect(heading).right, lessThan(tester.getRect(info).left));
    expect(tester.getCenter(heading).dy, tester.getCenter(info).dy);

    await tester.tap(info);
    await settle(tester);

    expect(find.text('Как проходить планы'), findsOneWidget);
    expect(find.textContaining('на главной странице'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(CourseProgressHeader), findsOneWidget);
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
    testWidgets('кнопка дня использует поля и размеры кнопки профиля', (
      tester,
    ) async {
      const parable = DayCard(
        id: 'parable',
        type: CardType.parable,
        body: 'Притча дня',
        source: 'Источник',
      );
      final progress = _FakeProgressRepository()
        ..seedRead({
          CardType.quote,
          CardType.advice,
          CardType.parable,
          CardType.reading,
        });
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(
            title: 'Название дня',
            cards: [..._cards, parable],
          ),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      final titleLeft = tester.getTopLeft(find.text('Название дня')).dx;
      expect(titleLeft, 16);
      final calendar = find.descendant(
        of: find.byType(DayWisdomTile),
        matching: find.byIcon(CupertinoIcons.calendar),
      );
      expect(tester.getCenter(calendar).dx, 44);
      final checks = find.descendant(
        of: find.byType(DayWisdomTile),
        matching: find.byIcon(CupertinoIcons.checkmark_alt),
      );
      expect(checks, findsNWidgets(2));
      final label = tester.getRect(find.text('Мудрость дня'));
      final subtitle = tester.getRect(
        find.text('Цитата, совет, притча и Евангелие'),
      );
      for (final check in checks.evaluate()) {
        final bounds = tester.getRect(find.byWidget(check.widget));
        expect(bounds.left, greaterThan(tester.getRect(calendar).right));
        expect(bounds.left, greaterThan(label.right));
        expect(bounds.bottom, lessThan(subtitle.top));
      }
      expect(label.left, 88);
    });

    testWidgets('ink кнопок дня занимает всю ширину экрана', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      final screen = tester.getRect(find.byType(TodayScreen));
      for (final row in find.byType(DayWisdomTile).evaluate()) {
        final ink = find.descendant(
          of: find.byWidget(row.widget),
          matching: find.byType(InkWell),
        );
        final bounds = tester.getRect(ink);
        expect(bounds.left, screen.left);
        expect(bounds.right, screen.right);
      }
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('длинная седмица видна целиком при масштабе $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(scale == 1.0 ? 320 : 800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        const week = 'Седмица 33-я по Пятидесятнице, по Богоявлении. Глас 8';
        final progress = _FakeProgressRepository()
          ..seedRead(_cards.map((card) => card.type).toSet());
        await tester.pumpWidget(
          buildApp(
            cardsRepository: _FakeCardsRepository(week: week),
            progressRepository: progress,
          ),
        );
        await settle(tester);

        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(week.toUpperCase()),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: week.length),
        );
        expect(boxes.map((box) => box.top).toSet().length, greaterThan(1));
        expect(
          tester.getBottomLeft(find.text(week.toUpperCase())).dy,
          lessThan(tester.getTopLeft(find.byType(WeekStrip)).dy),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('место седмицы постоянно при масштабе $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day + 10);
        final withoutWeek = DateTime(start.year, start.month, start.day + 2);
        final failed = DateTime(start.year, start.month, start.day + 3);
        final pending = Completer<Result<TodayCards>>();
        await tester.pumpWidget(
          buildApp(
            selectedDate: start,
            cardsRepository: _FakeCardsRepository(
              pendingDates: {dateKey(start): pending.future},
              failedDates: {dateKey(failed)},
            ),
          ),
        );
        await tester.pump();
        final stripBefore = tester.getRect(find.byType(WeekStrip));
        final contentBefore = tester.getRect(find.byType(PageView).last);

        pending.complete(
          const Success(
            TodayCards(cards: _cards, week: 'Неделя 16-я по Пятидесятнице'),
          ),
        );
        await settle(tester);
        expect(find.text('НЕДЕЛЯ 16-Я ПО ПЯТИДЕСЯТНИЦЕ'), findsOneWidget);
        expect(tester.getRect(find.byType(WeekStrip)), stripBefore);
        expect(tester.getRect(find.byType(PageView).last), contentBefore);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(TodayScreen)),
        );
        container.read(selectedDateProvider.notifier).select(withoutWeek);
        await settle(tester);
        expect(find.text('НЕДЕЛЯ 16-Я ПО ПЯТИДЕСЯТНИЦЕ'), findsNothing);
        expect(tester.getRect(find.byType(WeekStrip)), stripBefore);
        expect(tester.getRect(find.byType(PageView).last), contentBefore);

        container.read(selectedDateProvider.notifier).select(failed);
        await settle(tester);
        expect(find.byType(TodayOfflineView), findsOneWidget);
        expect(tester.getRect(find.byType(WeekStrip)), stripBefore);
        expect(tester.getRect(find.byType(PageView).last), contentBefore);
      });
    }

    testWidgets('седмица стоит над полоской дат, а не над памятью дня', (
      tester,
    ) async {
      // Седмица — свойство недели, а не дня: рядом с памятью она читалась
      // как часть титула святого.
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

      final weekTop = tester
          .getTopLeft(find.text('СЕДМИЦА 10-Я ПО ПЯТИДЕСЯТНИЦЕ'))
          .dy;
      final stripTop = tester.getTopLeft(find.byType(WeekStrip)).dy;
      expect(weekTop, lessThan(stripTop));

      // Память и пометка поста остаются при дне, ниже полоски.
      final nameTop = tester.getTopLeft(find.text('Мц. Христи́ны Тирской')).dy;
      expect(nameTop, greaterThan(stripTop));
      expect(
        tester.getTopLeft(find.text('ПОСТНЫЙ ДЕНЬ')).dy,
        greaterThan(stripTop),
      );
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

      final dayInk = find.ancestor(
        of: find.descendant(
          of: find.byType(DayNameHeader),
          matching: find.byIcon(CupertinoIcons.chevron_right),
        ),
        matching: find.byType(InkWell),
      );
      expect(tester.getRect(dayInk).left, 0);
      expect(tester.getRect(dayInk).right, 800);
      final dividerLine = find.descendant(
        of: find.byType(DayEntryDivider).first,
        matching: find.byType(Container),
      );
      expect(tester.getRect(dayInk).bottom, tester.getTopLeft(dividerLine).dy);
      final title = find.ancestor(
        of: find.descendant(
          of: find.byType(DayNameHeader),
          matching: find.byIcon(CupertinoIcons.chevron_right),
        ),
        matching: find.byType(Text),
      );
      expect(tester.getTopLeft(title).dx, 16);

      await tester.tapAt(Offset(1, tester.getCenter(dayInk).dy));
      await settle(tester);

      expect(find.byType(DayStoryScreen), findsOneWidget);
      expect(find.text('Рассказ о памяти дня.'), findsOneWidget);
    });

    testWidgets(
      'память дня без ссылки не рисует стрелку и не открывает рассказ',
      (tester) async {
        final progress = _FakeProgressRepository()
          ..seedRead(_cards.map((card) => card.type).toSet());
        await tester.pumpWidget(
          buildApp(
            cardsRepository: _FakeCardsRepository(
              title: 'Мц. Христи́ны Тирской',
            ),
            progressRepository: progress,
          ),
        );
        await settle(tester);

        expect(
          find.descendant(
            of: find.byType(DayNameHeader),
            matching: find.byIcon(CupertinoIcons.chevron_right),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('показывает полоску недели и одну кнопку дня', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);

      expect(find.byType(WeekStrip), findsOneWidget);
      expect(find.byType(DayWisdomTile), findsOneWidget);
      expect(entry('Мудрость дня'), findsOneWidget);
      expect(entry('ЗАКЛАДКИ'), findsNothing);
      expect(find.text('Копилка смыслов'), findsNothing);
    });

    testWidgets('полоска дат отделена от записей и навбара запасом', (
      tester,
    ) async {
      // Подписи «Сегодня» под полоской больше нет — она съедала высоту,
      // а выбранный день и так виден заливкой в самой полоске.
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet());
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      expect(find.text('Сегодня'), findsNothing);

      final stripBottom = tester.getBottomLeft(find.byType(WeekStrip)).dy;
      final firstTop = tester.getTopLeft(find.byType(DayWisdomTile).first).dy;
      expect(firstTop - stripBottom, greaterThanOrEqualTo(4));

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
    testWidgets('длинный стих предлагает раскрыть полную версию', (
      tester,
    ) async {
      final verseText = List.filled(30, 'Длинный стих').join(' ');
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

      expect(find.text('${verseText.substring(0, 150)}…'), findsOneWidget);
      expect(find.text(verseText), findsNothing);
      expect(find.byTooltip('Открыть полный текст'), findsOneWidget);
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

  group('переключение даты', () {
    testWidgets('календарная полоска не листается вместе с карточками', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      expect(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byType(WeekStrip),
        ),
        findsNothing,
      );
      expect(find.byType(WeekStrip), findsOneWidget);
    });

    test('страницы сохраняют соседние календарные даты через DST', () {
      final pages = CalendarPageMapper(DateTime(2026, 3, 8), initialPage: 0);

      expect(pages.dateForPage(1), DateTime(2026, 3, 9));
      expect(pages.pageForDate(DateTime(2026, 3, 9)), 1);
    });

    test('соседи листаются, остальные даты открываются через фэйд', () {
      for (final offset in [-1, 1]) {
        expect(
          CalendarPageMapper.transitionFor(
            currentPage: 100,
            targetPage: 100 + offset,
          ),
          CalendarPageTransition.animate,
        );
      }
      for (final offset in [-30, -2, 2, 30]) {
        expect(
          CalendarPageMapper.transitionFor(
            currentPage: 100,
            targetPage: 100 + offset,
          ),
          CalendarPageTransition.fade,
        );
      }
    });

    for (final offset in [-30, -2, 2, 30]) {
      testWidgets('выбор даты на $offset дней использует фэйд без сдвига', (
        tester,
      ) async {
        final start = DateTime(2026, 9, 23);
        final target = DateTime(2026, 9, 23 + offset);
        await tester.pumpWidget(buildApp(selectedDate: start));
        await settle(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TodayScreen)),
        );
        final changes = <DateTime>[];
        final subscription = container.listen(
          selectedDateProvider,
          (_, next) => changes.add(next),
        );
        addTearDown(subscription.close);
        final controller = tester
            .widget<PageView>(find.byType(PageView).last)
            .controller!;
        final initialPage = controller.page!;
        final fade = find.byWidgetPredicate(
          (widget) => widget is FadeTransition && widget.child is PageView,
        );

        container.read(selectedDateProvider.notifier).select(target);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(controller.page, initialPage);
        expect(find.byType(DayWisdomTile), findsWidgets);
        expect(
          tester.widget<FadeTransition>(fade).opacity.value,
          inExclusiveRange(0, 1),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(controller.page, initialPage + offset);
        await settle(tester);

        expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
        expect(changes.map(dateKey), [dateKey(target)]);
        expect(dateKey(container.read(selectedDateProvider)), dateKey(target));
      });
    }

    for (final offset in [-1, 1]) {
      testWidgets('выбор соседнего дня $offset сохраняет сдвиг', (
        tester,
      ) async {
        final start = DateTime(2026, 9, 23);
        await tester.pumpWidget(buildApp(selectedDate: start));
        await settle(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TodayScreen)),
        );
        final controller = tester
            .widget<PageView>(find.byType(PageView).last)
            .controller!;
        final initialPage = controller.page!;
        container
            .read(selectedDateProvider.notifier)
            .select(DateTime(2026, 9, 23 + offset));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect((controller.page! - initialPage).abs(), inExclusiveRange(0, 1));
        final fade = find.byWidgetPredicate(
          (widget) => widget is FadeTransition && widget.child is PageView,
        );
        expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
        await settle(tester);
        expect(controller.page, initialPage + offset);
      });
    }

    testWidgets('повторный выбор во время фэйда открывает последнюю дату', (
      tester,
    ) async {
      final start = DateTime(2026, 9, 23);
      await tester.pumpWidget(buildApp(selectedDate: start));
      await settle(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TodayScreen)),
      );
      final controller = tester
          .widget<PageView>(find.byType(PageView).last)
          .controller!;
      final initialPage = controller.page!;
      final changes = <DateTime>[];
      final subscription = container.listen(
        selectedDateProvider,
        (_, next) => changes.add(next),
      );
      addTearDown(subscription.close);
      final first = DateTime(2026, 9, 25);
      final last = DateTime(2026, 10, 23);
      container.read(selectedDateProvider.notifier).select(first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      container.read(selectedDateProvider.notifier).select(last);
      await settle(tester);

      expect(controller.page, initialPage + 30);
      expect(changes.map(dateKey), [dateKey(first), dateKey(last)]);
      final fade = find.byWidgetPredicate(
        (widget) => widget is FadeTransition && widget.child is PageView,
      );
      expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    });

    for (final fails in [false, true]) {
      testWidgets('фэйд ждёт загрузку в пустоте: ошибка=$fails', (
        tester,
      ) async {
        final start = DateTime(2026, 9, 23);
        final target = DateTime(2026, 9, 25);
        final pending = Completer<Result<TodayCards>>();
        await tester.pumpWidget(
          buildApp(
            selectedDate: start,
            cardsRepository: _FakeCardsRepository(
              pendingDates: {dateKey(target): pending.future},
            ),
          ),
        );
        await settle(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TodayScreen)),
        );
        final fade = find.byWidgetPredicate(
          (widget) => widget is FadeTransition && widget.child is PageView,
        );
        container.read(selectedDateProvider.notifier).select(target);
        await settle(tester);
        expect(find.byType(BrandLoadingView), findsNothing);
        expect(tester.widget<FadeTransition>(fade).opacity.value, 0);

        pending.complete(
          fails
              ? const Failure(AppFailure('Нет сети', kind: FailureKind.network))
              : const Success(TodayCards(cards: _cards)),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          tester.widget<FadeTransition>(fade).opacity.value,
          inExclusiveRange(0, 1),
        );
        expect(find.byType(BrandLoadingView), findsNothing);
        expect(
          find.byType(TodayOfflineView),
          fails ? findsOneWidget : findsNothing,
        );
        if (!fails) expect(find.byType(DayWisdomTile), findsWidgets);
        await settle(tester);
        expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
      });
    }

    testWidgets('свайп влево открывает следующий день', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.fling(
        find.byType(PageView).last,
        const Offset(-400, 0),
        1000,
      );
      await settle(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TodayScreen)),
      );
      expect(
        dateKey(container.read(selectedDateProvider)),
        dateKey(DateTime.now().add(const Duration(days: 1))),
      );
    });

    testWidgets('на будущем дне показывает непрочитанный статус', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.fling(
        find.byType(PageView).last,
        const Offset(-400, 0),
        1000,
      );
      await settle(tester);

      final futureEntries = tester.widgetList<DayWisdomTile>(
        find.byType(DayWisdomTile),
      );
      expect(futureEntries, isNotEmpty);
      expect(futureEntries.every((entry) => entry.isUnread), isTrue);

      final future = DateTime.now().add(const Duration(days: 1));
      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
      await settle(tester);

      expect(progress.marked, isNot(contains(CardType.quote)));
      expect(progress.visitedDays, isNot(contains(dateKey(future))));

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      expect(progress.marked, isNot(contains(CardType.reading)));
    });

    testWidgets('на прошлом дне показывает прочитанный статус', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet())
        ..seedReadOn(
          DateTime.now().subtract(const Duration(days: 1)),
          _cards.map((card) => card.type).toSet(),
        );
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.fling(
        find.byType(PageView).last,
        const Offset(400, 0),
        1000,
      );
      await settle(tester);

      final entries = tester.widgetList<DayWisdomTile>(
        find.byType(DayWisdomTile),
      );
      expect(entries, isNotEmpty);
      expect(entries.every((entry) => !entry.isUnread), isTrue);
    });

    testWidgets('прочтение прошлого дня не зажигает его лампадку', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet());
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.fling(
        find.byType(PageView).last,
        const Offset(400, 0),
        1000,
      );
      await settle(tester);
      await tester.tap(entry('Мудрость дня'));
      await settle(tester);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
      await settle(tester);

      expect(progress.marked, contains(CardType.quote));
      expect(progress.visitedDays, isNot(contains(dateKey(yesterday))));
    });

    testWidgets('скрывает календарные основы на другом дне', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead({
          CardType.quote,
          CardType.advice,
          CardType.reading,
          CardType.basics,
        });
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(cards: [..._cards, _basics]),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      await tester.fling(
        find.byType(PageView).last,
        const Offset(-400, 0),
        1000,
      );
      await settle(tester);

      // Календарные «Основы» чужого дня не должны притворяться темой курса:
      // виден только личный курс, и в нём своё название темы.
      expect(find.textContaining('Далее длинный текст темы'), findsNothing);
    });

    testWidgets('на другом дне показывает тот же личный курс', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead({
          CardType.quote,
          CardType.advice,
          CardType.reading,
          CardType.basics,
        });
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(cards: [..._cards, _basics]),
          progressRepository: progress,
          courseTopic: _basics,
        ),
      );
      await settle(tester);

      await tester.fling(
        find.byType(PageView).last,
        const Offset(-400, 0),
        1000,
      );
      await settle(tester);

      expect(find.byType(CourseProgressHeader), findsOneWidget);
      expect(find.text('Мудрость дня'), findsOneWidget);
    });

    testWidgets('открывает дату, выбранную до показа экрана', (tester) async {
      final repo = _FakeCardsRepository();
      final selected = DateTime(2026, 1, 1);
      await tester.pumpWidget(
        buildApp(cardsRepository: repo, selectedDate: selected),
      );
      await settle(tester);

      expect(repo.requested, contains(dateKey(selected)));
    });

    testWidgets('предзагружает карточки соседних страниц', (tester) async {
      final repo = _FakeCardsRepository();
      await tester.pumpWidget(buildApp(cardsRepository: repo));
      await settle(tester);

      final today = DateTime.now();
      expect(
        repo.requested,
        contains(dateKey(today.add(const Duration(days: 1)))),
      );
      expect(
        repo.requested,
        contains(dateKey(today.subtract(const Duration(days: 1)))),
      );
    });

    testWidgets('тап по дню недели запрашивает карточки этой даты', (
      tester,
    ) async {
      final repo = _FakeCardsRepository();
      await tester.pumpWidget(buildApp(cardsRepository: repo));
      await settle(tester);

      final today = DateTime.now();
      final other = today.subtract(Duration(days: today.weekday == 1 ? -1 : 1));

      await tester.tap(find.text('${other.day}').first);
      await settle(tester);

      expect(repo.requested, contains(dateKey(other)));
      expect(find.text('Вернуться'), findsOneWidget);
      await tester.tap(find.text('Вернуться'));
      await settle(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TodayScreen)),
      );
      expect(dateKey(container.read(selectedDateProvider)), dateKey(today));
      expect(find.text('Вернуться'), findsNothing);
    });

    testWidgets('чужая дата не меняет прогресс сегодняшней сессии', (
      tester,
    ) async {
      // «Лампадка» отмечает дни, когда юзер заходил за контентом ИМЕННО
      // этого дня: чтение вчерашнего не должно зажигать вчерашний огонёк
      // или менять статус карточек на сегодня. Само прочтение хранится
      // отдельно в истории этой даты.
      //
      // Сегодняшний день засеян прочитанным, чтобы различать его прогресс
      // с записью для выбранной чужой даты.
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);
      final before = {...progress.readTypes};

      final today = DateTime.now();
      final other = today.subtract(Duration(days: today.weekday == 1 ? -1 : 1));
      await tester.tap(find.text('${other.day}').first);
      await settle(tester);

      await tester.tap(entry('Мудрость дня'));
      await settle(tester);

      expect(progress.readTypes, before, reason: 'прогресс сдвинулся');
      expect(progress.visitedDays, isEmpty);
    });
  });

  group('«Лампадка» в полоске недели', () {
    testWidgets('дни с активностью помечены огоньком', (tester) async {
      final today = DateTime.now();
      final progress = _FakeProgressRepository()..seedVisited({dateKey(today)});

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      final strip = tester.widget<WeekStrip>(find.byType(WeekStrip));
      expect(strip.litDays, contains(dateKey(today)));
    });
  });

  group('конец сессии', () {
    testWidgets('после последней карточки просмотрщик закрывается крестиком', (
      tester,
    ) async {
      // Экрана завершения нет вовсе. Любая надпись на нём выходила либо
      // неправдой («увидимся завтра», когда осталось Евангелие), либо
      // церемонией: «Сегодня» и так показывает, что не пройдено.
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
      expect(find.textContaining('Чтобы не остановиться'), findsOneWidget);
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
}
