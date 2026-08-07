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
import 'package:lampada/features/daily_cards/presentation/screens/card_viewer_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/today_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/daily_card_action_button.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_entry_row.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/week_strip.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/domain/repositories/reading_repository.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:lampada/features/reading/presentation/screens/reading_screen.dart';
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

/// Карточки, которые попадают в просмотрщик: чтение живёт отдельным треком
/// и своей страницы там не получает.
final _pageCards = _cards
    .where((c) => c.type != CardType.reading && c.type != CardType.basics)
    .toList();

const _basics = DayCard(
  id: 'basics',
  type: CardType.basics,
  body: 'Тема 1. О вере и жизни христианина. Далее длинный текст темы.',
  source: 'Азбука веры',
  title: 'О вере и жизни христианина',
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
  _FakeCardsRepository({
    this.cards = _cards,
    this.refreshedCards,
    this.week,
    this.title,
    this.isFast = false,
  });

  final requested = <String>[];
  final List<DayCard> cards;
  final Map<String, List<DayCard>>? refreshedCards;
  final String? week;
  final String? title;
  final bool isFast;
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
    return Success(
      TodayCards(
        cards: _cachedCards[key] ?? cards,
        week: week,
        title: title,
        isFast: isFast,
      ),
    );
  }
}

class _FakeProgressRepository implements DayProgressRepository {
  Set<CardType> _read = {};
  Set<String> _visited = {};

  DayProgress get _current =>
      DayProgress(readTypes: _read, visitedDays: _visited);

  @override
  Future<Result<DayProgress>> loadToday() async => Success(_current);

  /// Типы, отмеченные именно в ходе теста. Отдельно от [readTypes], потому что
  /// автооткрытие теперь доходит и до Евангелия с курсом: тестам про них
  /// приходится заранее засеивать всё прочитанным, и по итоговому набору уже
  /// не отличить «отметили сейчас» от «засеяли».
  final marked = <CardType>[];

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    marked.add(type);
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

  /// Записи дня различаются подписью, а не типом виджета: сессия, Евангелие
  /// и курс рисуются одним [DayEntryRow] — рамок и блоков-героев больше нет.
  Finder entry(String label) => find.ancestor(
    of: find.textContaining(label),
    matching: find.byType(DayEntryRow),
  );

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

      // Вход в курс называет тему и её номер: до этого блок обещал «Основы
      // веры» и ничего больше, тогда как чтение рядом честно показывало отрывок.
      expect(entry('ОСНОВЫ ВЕРЫ'), findsOneWidget);
      expect(find.text('ОСНОВЫ ВЕРЫ · 1'), findsOneWidget);
      expect(find.text('О вере и жизни христианина'), findsOneWidget);
    });

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

    testWidgets('показывает полоску недели и блоки дня', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      expect(find.byType(WeekStrip), findsOneWidget);
      // Две карточки сессии плюс вход в Евангелие — одним типом виджета.
      expect(find.byType(DayEntryRow), findsNWidgets(_cards.length));
      expect(entry('ЕВАНГЕЛИЕ ДНЯ'), findsOneWidget);
    });

    testWidgets('блок показывает начало текста карточки', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      expect(find.text('Первая карточка'), findsOneWidget);
      expect(find.text('Последняя карточка'), findsOneWidget);
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
      final firstTop = tester.getTopLeft(find.byType(DayEntryRow).first).dy;
      expect(firstTop - stripBottom, greaterThanOrEqualTo(4));

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(
        list.padding,
        const EdgeInsets.fromLTRB(20, 4, 20, kFloatingNavInset + 32),
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
      // День пройден целиком, включая чтение: иначе автооткрытие уведёт
      // в ридер Евангелия и до блоков тест не дойдёт.
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);
      await dismissAutoOpened(tester);

      expect(find.byType(DayEntryRow), findsNWidgets(_cards.length));
      expect(entry('ЕВАНГЕЛИЕ ДНЯ'), findsOneWidget);
      expect(find.text('Пройти снова'), findsNothing);
    });
  });

  group('полноэкранный просмотр', () {
    testWidgets('в просмотрщике ровно столько страниц, сколько карточек', (
      tester,
    ) async {
      // Отдельной страницы завершения нет: она объявляла день оконченным,
      // хотя Евангелие и курс остаются на сегодня.
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      await tester.tap(entry('ЦИТАТА'));
      await settle(tester);

      final pageView = tester.widget<PageView>(
        find.descendant(
          of: find.byType(CardViewerScreen),
          matching: find.byType(PageView),
        ),
      );
      expect(pageView.childrenDelegate.estimatedChildCount, _pageCards.length);
    });

    testWidgets('тап по герою курса открывает ридер и засчитывает тему', (
      tester,
    ) async {
      // Курс засеян прочитанным, иначе автооткрытие само уведёт в его ридер
      // и до блока-героя тест не доберётся.
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

      await tester.tap(entry('ОСНОВЫ ВЕРЫ'));
      await settle(tester);

      expect(find.byType(CourseReaderScreen), findsOneWidget);
      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.text(_basics.body), findsOneWidget);
      expect(progress.marked, contains(CardType.basics));
    });

    testWidgets('тап по блоку открывает карточку без таб-бара', (tester) async {
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(entry('ЦИТАТА'));
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
      await tester.tap(entry('СОВЕТ'));
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

      await tester.tap(entry('ЦИТАТА'));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.byType(DayEntryRow), findsNWidgets(_cards.length));
    });

    testWidgets('открытая карточка сразу засчитывается прочитанной', (
      tester,
    ) async {
      final progress = _FakeProgressRepository();
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(entry('ЦИТАТА'));
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

      await tester.tap(entry('ЕВАНГЕЛИЕ ДНЯ'));
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

      await tester.tap(entry('ЦИТАТА'));
      await settle(tester);

      final viewer = tester.widget<CardViewerScreen>(
        find.byType(CardViewerScreen),
      );
      // Просмотрщик — это сессия дня и только она. Евангелие и курс живут
      // отдельными треками со своими ридерами.
      expect(
        viewer.cards.map((c) => c.type),
        isNot(contains(CardType.reading)),
      );
      expect(viewer.cards.map((c) => c.type), isNot(contains(CardType.basics)));
    });

    testWidgets('сессия заканчивается на последней карточке, а не в ридере', (
      tester,
    ) async {
      // Раньше с последней карточки кнопка менялась на «Читать» и утягивала
      // в постишное Евангелие. Из-за этого сессия не кончалась там, где
      // обещала, и три её карточки было не отличить от пяти частей дня.
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(entry('ЦИТАТА'));
      await settle(tester);
      await tester.tap(find.byType(DailyCardNextButton));
      await settle(tester);

      expect(find.text('Читать'), findsNothing);
      expect(find.byType(ReadingScreen), findsNothing);
    });

    testWidgets('открытие ридера засчитывает чтение прочитанным', (
      tester,
    ) async {
      final progress = _FakeProgressRepository();
      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(entry('ЕВАНГЕЛИЕ ДНЯ'));
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

      // Календарные «Основы» чужого дня не должны притворяться темой курса:
      // виден только личный курс, и в нём своё название темы.
      expect(find.textContaining('Далее длинный текст темы'), findsNothing);
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

      expect(entry('ОСНОВЫ ВЕРЫ'), findsOneWidget);
      expect(find.text('О вере и жизни христианина'), findsOneWidget);
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
      await tester.tap(entry('ОСНОВЫ ВЕРЫ'));
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

      await tester.tap(entry('ЦИТАТА'));
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

  group('конец сессии', () {
    testWidgets('с последней карточки «Готово» возвращает на «Сегодня»', (
      tester,
    ) async {
      // Экрана завершения нет вовсе. Любая надпись на нём выходила либо
      // неправдой («увидимся завтра», когда осталось Евангелие), либо
      // церемонией: «Сегодня» и так показывает, что не пройдено.
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);

      await tester.tap(entry('ЦИТАТА'));
      await settle(tester);
      final pageView = find.descendant(
        of: find.byType(CardViewerScreen),
        matching: find.byType(PageView),
      );
      for (var i = 1; i < _pageCards.length; i++) {
        await tester.fling(pageView, const Offset(-400, 0), 1000);
        await settle(tester);
      }

      expect(find.byType(DailyCardDoneButton), findsOneWidget);
      await tester.tap(find.byType(DailyCardDoneButton));
      await settle(tester);

      expect(find.byType(CardViewerScreen, skipOffstage: false), findsNothing);
      expect(find.byType(DayEntryRow), findsWidgets);
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

      // Автооткрытая карточка ещё на экране — вопрос не должен её перебивать.
      expect(find.byType(CardViewerScreen), findsOneWidget);
      expect(find.byType(ReminderPermissionScreen), findsNothing);
    });

    testWidgets('после закрытия первой карточки спрашиваем', (tester) async {
      await pumpFresh(tester);

      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(find.byType(ReminderPermissionScreen), findsOneWidget);
      expect(find.textContaining('Чтобы не остановиться'), findsOneWidget);
    });

    testWidgets('спрашиваем один раз, даже после отказа', (tester) async {
      await pumpFresh(tester);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      await tester.tap(find.text('Не сейчас'));
      await settle(tester);
      expect(find.byType(ReminderPermissionScreen), findsNothing);

      // Открыли и закрыли ещё одну карточку — второй раз не спрашиваем:
      // системное разрешение всё равно показывается только однажды.
      await tester.tap(entry('СОВЕТ'));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      expect(find.byType(ReminderPermissionScreen), findsNothing);
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

    testWidgets('после сессии очередь доходит до Евангелия', (tester) async {
      // Очередь входа — цитата → совет → притча → Евангелие → основы,
      // по шагу за вход. Сессия дня кончилась, следующий вход ведёт в ридер.
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice});

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      expect(find.byType(ReadingScreen), findsOneWidget);
      expect(find.byType(CardViewerScreen), findsNothing);
    });

    testWidgets('после Евангелия очередь доходит до курса', (tester) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});

      await tester.pumpWidget(
        buildApp(
          cardsRepository: _FakeCardsRepository(cards: [..._cards, _basics]),
          progressRepository: progress,
        ),
      );
      await settle(tester);

      expect(find.byType(CourseReaderScreen), findsOneWidget);
    });

    testWidgets('всё прочитано — открываются блоки, а не просмотрщик', (
      tester,
    ) async {
      final progress = _FakeProgressRepository()
        ..seedRead({CardType.quote, CardType.advice, CardType.reading});

      await tester.pumpWidget(buildApp(progressRepository: progress));
      await settle(tester);

      expect(find.byType(CardViewerScreen), findsNothing);
      expect(find.byType(ReadingScreen), findsNothing);
      expect(find.byType(DayEntryRow), findsNWidgets(_cards.length));
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
      expect(entry('ЕВАНГЕЛИЕ ДНЯ'), findsOneWidget);
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
}
