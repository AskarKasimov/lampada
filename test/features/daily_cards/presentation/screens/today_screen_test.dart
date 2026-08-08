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
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/card_viewer_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/today_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/basics_course_link.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/basics_hero_block.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_swipe_nudge.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_card_block.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/reading_hero_block.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/session_done_view.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/week_strip.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/domain/repositories/reading_repository.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:lampada/features/reading/presentation/screens/reading_screen.dart';
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
  body: 'О вере и жизни христианина',
  source: 'Азбука веры',
);

/// Ридер не должен ходить в сеть из виджет-тестов.
class _FakeReadingRepository implements ReadingRepository {
  @override
  Future<Result<DailyReading>> getReading(String reference) async =>
      const Success(
        DailyReading(
          label: 'Ин.10:1–9',
          verses: [Verse(number: 1, chapter: 10, text: 'Истинно говорю вам')],
        ),
      );
}

class _FakeCardsRepository implements DayCardsRepository {
  _FakeCardsRepository({this.cards = _cards, this.refreshedCards});

  final requested = <String>[];
  final List<DayCard> cards;
  final Map<String, List<DayCard>>? refreshedCards;
  final _cachedCards = <String, List<DayCard>>{};

  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    final key = dateKey(date);
    requested.add(key);
    if (forceRefresh && refreshedCards?[key] != null) {
      _cachedCards[key] = refreshedCards![key]!;
    }
    return Success(TodayCards(cards: _cachedCards[key] ?? cards));
  }
}

class _FakeProgressRepository implements DayProgressRepository {
  Set<CardType> _read = {};
  Set<String> _visited = {};

  DayProgress get _current =>
      DayProgress(readTypes: _read, visitedDays: _visited);

  @override
  Future<Result<DayProgress>> loadToday() async => Success(_current);

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    _read = {..._read, type};
    _visited = {..._visited, dateKey(DateTime.now())};
    return Success(_current);
  }

  Set<CardType> get readTypes => _read;
  Set<String> get visitedDays => _visited;

  void seedRead(Set<CardType> types) => _read = types;
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildApp({
    DayCardsRepository? cardsRepository,
    DayProgressRepository? progressRepository,
    DateTime? selectedDate,
  }) => ProviderScope(
    overrides: [
      dayCardsRepositoryProvider.overrideWithValue(
        cardsRepository ?? _FakeCardsRepository(),
      ),
      dayProgressRepositoryProvider.overrideWithValue(
        progressRepository ?? _FakeProgressRepository(),
      ),
      readingRepositoryProvider.overrideWithValue(_FakeReadingRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
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

  /// Каждый вход сам открывает первую непрочитанную карточку на весь экран.
  /// Тестам про блоки её надо сперва закрыть; когда день уже прочитан,
  /// открывать нечего и хелпер ничего не делает.
  Future<void> dismissAutoOpened(WidgetTester tester) async {
    if (find.byType(CardViewerScreen).evaluate().isEmpty) return;
    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);
  }

  group('вкладка «Сегодня»', () {
    testWidgets('показывает последовательный курс отдельной карточкой', (
      tester,
    ) async {
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

      expect(find.byType(BasicsHeroBlock), findsOneWidget);
      expect(find.text('ПОСЛЕДОВАТЕЛЬНЫЙ КУРС'), findsOneWidget);
      expect(
        find.text('Следующая тема откроется на следующий день после прочтения'),
        findsOneWidget,
      );
    });

    testWidgets('показывает полоску недели и блоки дня', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      expect(find.byType(WeekStrip), findsOneWidget);
      // Чтение вынесено из общего ряда отдельным блоком-героем, поэтому
      // обычных блоков на один меньше, чем карточек дня.
      expect(find.byType(ReadingHeroBlock), findsOneWidget);
      expect(find.byType(DayCardBlock), findsNWidgets(_cards.length - 1));
      expect(find.text('Сегодня'), findsOneWidget);
    });

    testWidgets('блок показывает начало текста карточки', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      expect(find.text('Первая карточка'), findsOneWidget);
      expect(find.text('Последняя карточка'), findsOneWidget);
    });

    testWidgets('дата отделена от карточек и навбара запасом', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet());
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      final dateBottom = tester.getBottomLeft(find.text('Сегодня')).dy;
      final readingTop = tester.getTopLeft(find.byType(ReadingHeroBlock)).dy;
      expect(readingTop - dateBottom, greaterThanOrEqualTo(22));

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(
        list.padding,
        const EdgeInsets.fromLTRB(20, 12, 20, kFloatingNavInset + 32),
      );
    });

    testWidgets('pull-to-refresh запрашивает свежие карточки дня', (
      tester,
    ) async {
      const refreshed = DayCard(
        id: 'quote-refreshed',
        type: CardType.quote,
        body: 'Свежая карточка',
        source: 'Источник 1',
      );
      final today = dateKey(DateTime.now());
      final progress = _FakeProgressRepository()
        ..seedRead(_cards.map((card) => card.type).toSet());
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(
            refreshedCards: {
              today: [refreshed, ..._cards.skip(1)],
            },
          ),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      expect(find.text('Первая карточка'), findsOneWidget);
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await settle(tester);

      expect(find.text('Свежая карточка'), findsOneWidget);
    });

    testWidgets('прочитанные блоки видны и после прохождения дня', (
      tester,
    ) async {
      // Раньше пройденный день встречал экраном завершения с «Пройти снова»,
      // и чтобы перечитать одну карточку, надо было запускать день заново.
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice});

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);
      await dismissAutoOpened(tester);

      expect(find.byType(DayCardBlock), findsNWidgets(_cards.length - 1));
      expect(find.byType(ReadingHeroBlock), findsOneWidget);
      expect(find.text('Пройти снова'), findsNothing);
    });
  });

  group('полноэкранный просмотр', () {
    testWidgets('финальный экран не меняет высоту области карточки', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.tap(find.byType(DayCardBlock).first);
      await settle(tester);

      final pageView = find.descendant(
        of: find.byType(CardViewerScreen),
        matching: find.byType(PageView),
      );
      final before = tester.getSize(pageView).height;
      await tester.fling(pageView, const Offset(-400, 0), 1000);
      await settle(tester);
      await tester.fling(pageView, const Offset(-400, 0), 1000);
      await settle(tester);

      expect(find.byType(SessionDoneView), findsOneWidget);
      expect(tester.getSize(pageView).height, before);
    });

    testWidgets('тап по герою курса открывает ридер и засчитывает тему', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(cards: [..._cards, _basics]),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      await tester.tap(find.byType(BasicsHeroBlock));
      await settle(tester);

      expect(find.byType(CourseReaderScreen), findsOneWidget);
      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.text(_basics.body), findsOneWidget);
      expect(progress.readTypes, contains(CardType.basics));
    });

    testWidgets('тап по блоку открывает карточку без таб-бара', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(find.byType(DayCardBlock).first);
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

    testWidgets('открывается именно та карточка, по которой тапнули', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      // Второй обычный блок — «Совет дня». Чтение в этот ряд не входит.
      await tester.tap(find.byType(DayCardBlock).at(1));
      await settle(tester);

      expect(
        find.descendant(
          of: find.byType(CardViewerScreen),
          matching: find.text('Последняя карточка'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('крестик закрывает просмотрщик и возвращает к блокам', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(find.byType(DayCardBlock).first);
      await settle(tester);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.byType(DayCardBlock), findsNWidgets(_cards.length - 1));
    });

    testWidgets('открытая карточка сразу засчитывается прочитанной', (
      tester,
    ) async {
      final progress = _FakeProgressRepository();
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(find.byType(DayCardBlock).first);
      await settle(tester);

      expect(progress.readTypes, contains(CardType.quote));
      expect(progress.readTypes, isNot(contains(CardType.advice)));
    });
  });

  group('чтение дня без промежуточного экрана', () {
    testWidgets('тап по блоку «Чтение» открывает ридер сразу', (tester) async {
      // Экран с одной ссылкой «Ин.10:1–9» и кнопкой «Читать» был лишним
      // шагом: он ничего не показывал, кроме того, что уже есть в блоке.
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(find.byType(ReadingHeroBlock));
      await settle(tester);

      expect(find.byType(ReadingScreen), findsOneWidget);
      expect(find.byType(CardViewerScreen), findsNothing);
    });

    testWidgets('карточка чтения не получает страницы в просмотрщике', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(find.byType(DayCardBlock).first);
      await settle(tester);

      final viewer = tester.widget<CardViewerScreen>(
        find.byType(CardViewerScreen),
      );
      expect(
        viewer.cards.map((c) => c.type),
        isNot(contains(CardType.reading)),
      );
      expect(viewer.reading?.reference, 'Jn.10:1-9');
    });

    testWidgets('свайп ведёт к финалу с чтением Евангелия', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(find.byType(DayCardBlock).first);
      await settle(tester);

      expect(find.text('Свайпните влево'), findsNothing);
      expect(find.byType(CardSwipeNudge), findsOneWidget);
      expect(find.text('Дальше'), findsNothing);

      final pageView = find.descendant(
        of: find.byType(CardViewerScreen),
        matching: find.byType(PageView),
      );
      await tester.fling(pageView, const Offset(-400, 0), 1000);
      await settle(tester);
      await tester.fling(pageView, const Offset(-400, 0), 1000);
      await settle(tester);

      expect(find.byType(SessionDoneView), findsOneWidget);
      expect(find.text('Пройти снова'), findsNothing);
      expect(find.text('Читать Евангелие'), findsOneWidget);
      await tester.tap(find.text('Читать Евангелие'));
      await settle(tester);
      expect(find.byType(ReadingScreen), findsOneWidget);
    });

    testWidgets('подсказка свайпа не повторяется при возврате к карточке', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(find.byType(DayCardBlock).first);
      await settle(tester);

      final pageView = find.descendant(
        of: find.byType(CardViewerScreen),
        matching: find.byType(PageView),
      );
      await tester.fling(pageView, const Offset(-400, 0), 1000);
      await settle(tester);
      await tester.fling(pageView, const Offset(-400, 0), 1000);
      await settle(tester);
      await tester.fling(pageView, const Offset(400, 0), 1000);
      await settle(tester);
      await tester.fling(pageView, const Offset(400, 0), 1000);
      await settle(tester);

      expect(find.byType(CardSwipeNudge), findsNothing);
    });

    testWidgets('открытие ридера засчитывает чтение прочитанным', (
      tester,
    ) async {
      final progress = _FakeProgressRepository();
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(find.byType(ReadingHeroBlock));
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

    test('соседний день листается, а далёкий открывается сразу', () {
      expect(
        CalendarPageMapper.transitionFor(currentPage: 10, targetPage: 11),
        CalendarPageTransition.animate,
      );
      expect(
        CalendarPageMapper.transitionFor(currentPage: 10, targetPage: 13),
        CalendarPageTransition.jump,
      );
    });

    testWidgets('свайп влево открывает следующий день', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await settle(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TodayScreen)),
      );
      expect(
        dateKey(container.read(selectedDateProvider)),
        dateKey(DateTime.now().add(const Duration(days: 1))),
      );
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

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await settle(tester);

      final calendarBasics = find.byWidgetPredicate(
        (widget) =>
            widget is DayCardBlock && widget.card.type == CardType.basics,
      );
      expect(calendarBasics.hitTestable(), findsNothing);
    });

    testWidgets('на другом дне оставляет ссылку на текущую тему курса', (
      tester,
    ) async {
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

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await settle(tester);

      expect(find.byType(BasicsHeroBlock), findsNothing);
      expect(find.text('Основы веры'), findsOneWidget);
    });

    testWidgets('тап по ссылке курса на другом дне открывает ридер', (
      tester,
    ) async {
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

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await settle(tester);
      await tester.tap(find.byType(BasicsCourseLink));
      await settle(tester);

      expect(find.byType(CourseReaderScreen), findsOneWidget);
      expect(find.byType(CardViewerScreen), findsNothing);
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
      await dismissAutoOpened(tester);

      final today = DateTime.now();
      final other = today.subtract(Duration(days: today.weekday == 1 ? -1 : 1));

      await tester.tap(find.text('${other.day}').first);
      await settle(tester);

      expect(repo.requested, contains(dateKey(other)));
      expect(
        find.text(dateKey(other) == dateKey(today) ? 'Сегодня' : 'Сегодня'),
        findsNothing,
      );
    });

    testWidgets('на чужой дате прогресс не пишется', (tester) async {
      // «Лампадка» отмечает дни, когда юзер заходил за контентом ИМЕННО
      // этого дня: чтение вчерашнего не должно зажигать вчерашний огонёк.
      //
      // День засеян прочитанным целиком, чтобы автооткрытие за сегодня не
      // сработало и не подмешало свою запись в проверку.
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);
      final before = {...progress.readTypes};

      final today = DateTime.now();
      final other = today.subtract(Duration(days: today.weekday == 1 ? -1 : 1));
      await tester.tap(find.text('${other.day}').first);
      await settle(tester);

      await tester.tap(find.byType(DayCardBlock).first);
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
      await dismissAutoOpened(tester);

      final strip = tester.widget<WeekStrip>(find.byType(WeekStrip));
      expect(strip.litDays, contains(dateKey(today)));
    });
  });

  group('автооткрытие первой непрочитанной карточки', () {
    testWidgets('первый вход открывает цитату на весь экран', (tester) async {
      // Момент «ага» из §1: открыл приложение и сразу получил одну мысль.
      // Список блоков отодвигал его за один тап.
      await tester.pumpWidget(buildApp());
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CardViewerScreen),
          matching: find.text('Первая карточка'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('следующий вход открывает совет, если до него не дошли', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()..seedRead({CardType.quote});

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      expect(
        find.descendant(
          of: find.byType(CardViewerScreen),
          matching: find.text('Последняя карточка'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('всё прочитано — открываются блоки, а не просмотрщик', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.byType(DayCardBlock), findsNWidgets(_cards.length - 1));
    });

    testWidgets('закрыл просмотрщик — он не открывается заново', (
      tester,
    ) async {
      // Прогресс пишется асинхронно, и на один кадр карточка ещё выглядит
      // непрочитанной: без флага возврат к блокам зацикливался.
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.byType(ReadingHeroBlock), findsOneWidget);
    });

    testWidgets('на чужой дате ничего не открывается само', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      final today = DateTime.now();
      final other = today.subtract(Duration(days: today.weekday == 1 ? -1 : 1));
      await tester.tap(find.text('${other.day}').first);
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
    });
  });

  testWidgets('указывает номер темы в заголовке личного курса', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BasicsHeroBlock(
            card: _basics.copyWith(id: 'basics-topic-42'),
            isRead: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Основы веры'), findsOneWidget);
  });
}
