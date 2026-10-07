import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bible/presentation/screens/bible_tab_screen.dart';
import 'package:lampada/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/day_wisdom_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/today_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_progress_header.dart';
import 'package:lampada/features/profile/presentation/screens/profile_screen.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/domain/repositories/reading_repository.dart';
import 'package:lampada/features/reading/presentation/providers/providers.dart';
import 'package:lampada/features/shell/presentation/providers/shell_providers.dart';
import 'package:lampada/features/shell/presentation/screens/app_shell.dart';
import 'package:lampada/features/shell/presentation/widgets/floating_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(
    DateTime date, {
    bool forceRefresh = false,
  }) async => Success(
    TodayCards(
      cards: const [
        DayCard(
          id: 'quote',
          type: CardType.quote,
          body: 'Мысль дня',
          source: 'Источник',
        ),
        DayCard(
          id: 'reading',
          type: CardType.reading,
          body: 'Ин.10:1–9',
          source: 'Азбука веры',
          reference: 'Jn.10:1-9',
        ),
        DayCard(
          id: 'basics-topic-1',
          type: CardType.basics,
          body: 'Первая тема курса',
          title: 'О вере и жизни христианина',
          source: 'Источник',
        ),
      ],
    ),
  );
}

class _FakeProgressRepository implements DayProgressRepository {
  Set<CardType> _read = {};
  Set<String> _visited = {};
  Map<String, Set<CardType>> _history = {};

  DayProgress get _current => DayProgress(
    readTypes: _read,
    visitedDays: _visited,
    readTypesByDate: _history,
  );

  @override
  Future<Result<DayProgress>> loadToday() async => Success(_current);

  @override
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) async {
    _read = {..._read, type};
    final key = dateKey(date ?? DateTime.now());
    _history = {
      ..._history,
      key: {...?_history[key], type},
    };
    _visited = {..._visited, dateKey(DateTime.now())};
    return Success(_current);
  }
}

/// Евангелие дня не должно ходить в сеть: иначе плитка «Мудрость дня»
/// остаётся в загрузке и не открывается.
class _FakeReadingRepository implements ReadingRepository {
  @override
  Future<Result<DailyReading>> getReading(
    String reference, {
    bool forceRefresh = false,
  }) async => const Success(
    DailyReading(
      label: 'Ин.10:1–9',
      verses: [Verse(number: 1, chapter: 10, text: 'Первый стих')],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  /// Разрешение на напоминания спрашивается после первой закрытой карточки
  /// и накрывает шелл своим маршрутом. Тестам про навигацию это мешает,
  /// поэтому считаем, что спросили раньше.
  setUp(() async {
    SharedPreferences.setMockInitialValues({'flutter.reminders_asked': true});
    prefs = await SharedPreferences.getInstance();
  });

  /// IndexedStack строит все четыре вкладки сразу, поэтому Профиль читает
  /// настройку темы уже на старте — prefs нужны даже тесту про «Главную».
  Widget buildApp({TargetPlatform? platform}) => ProviderScope(
    overrides: [
      dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
      dayProgressRepositoryProvider.overrideWithValue(
        _FakeProgressRepository(),
      ),
      readingRepositoryProvider.overrideWithValue(_FakeReadingRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      theme: AppTheme.light.copyWith(platform: platform),
      home: const AppShell(),
    ),
  );

  /// Иконка закладки живёт и в навигации, и кнопкой сохранения на карточке —
  /// искать её по всему дереву неоднозначно.
  Finder tabIcon(IconData icon) => find.descendant(
    of: find.byType(FloatingNavBar),
    matching: find.byIcon(icon),
  );

  // StreakFlame крутится бесконечно — pumpAndSettle никогда не осядет.
  // Прокачиваем с запасом: переходы маршрутов длиннее анимации карточки,
  // а недокачанный переход держит AbsorbPointer и тапы не доходят.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Библия открывается вкладкой, а не модальным экраном', (
    tester,
  ) async {
    await prefs.setString(
      'bible_chapter_v1:Mt.1',
      '{"book":"Mt","number":1,"verses":[{"number":1,"text":"Первый стих Матфея"}]}',
    );
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.book));
    await settle(tester);
    final reader = find.byType(BibleTabScreen);
    expect(reader, findsOneWidget);
    expect(ModalRoute.of(tester.element(reader))!.fullscreenDialog, isFalse);
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(tabIcon(CupertinoIcons.book_fill), findsOneWidget);
    expect(find.byTooltip('Закрыть'), findsNothing);
  });

  testWidgets('кнопки читалки Библии не уходят под навбар', (tester) async {
    await prefs.setString(
      'bible_chapter_v1:Mt.1',
      '{"book":"Mt","number":1,"verses":[{"number":1,"text":"Первый стих Матфея"}]}',
    );
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.book));
    await settle(tester);
    final navTop = tester.getTopLeft(find.byType(FloatingNavBar)).dy;
    final share = find.ancestor(
      of: find.byIcon(CupertinoIcons.share),
      matching: find.byType(IconButton),
    );
    expect(share, findsOneWidget);
    expect(tester.getBottomLeft(share).dy, lessThanOrEqualTo(navTop));
  });

  testWidgets('каталог Библии открывается под видимым навбаром', (
    tester,
  ) async {
    await prefs.setString(
      'bible_chapter_v1:Mt.1',
      '{"book":"Mt","number":1,"verses":[{"number":1,"text":"Первый стих Матфея"}]}',
    );
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.book));
    await settle(tester);
    await tester.tap(find.byTooltip('Книги и главы'));
    await settle(tester);
    expect(find.text('Новый Завет'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });

  testWidgets('из Библии навбар переключает на Профиль', (tester) async {
    await prefs.setString(
      'bible_chapter_v1:Mt.1',
      '{"book":"Mt","number":1,"verses":[{"number":1,"text":"Первый стих Матфея"}]}',
    );
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.book));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.person));
    await settle(tester);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(BibleTabScreen), findsNothing);
    expect(tabIcon(CupertinoIcons.person_fill), findsOneWidget);
  });

  testWidgets('Библия впервые открывает Матфея и возвращает последний стих', (
    tester,
  ) async {
    await prefs.setString(
      'bible_chapter_v1:Mt.1',
      '{"book":"Mt","number":1,"verses":[{"number":1,"text":"Первый стих Матфея"},{"number":2,"text":"Второй стих Матфея"}]}',
    );
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.book));
    await settle(tester);
    expect(find.text('Первый стих Матфея'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await settle(tester);
    expect(find.text('Второй стих Матфея'), findsOneWidget);
    await tester.tap(tabIcon(CupertinoIcons.sunset));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.book));
    await settle(tester);
    expect(find.text('Второй стих Матфея'), findsOneWidget);
  });

  testWidgets(
    'после перезапуска Библия открывает сохранённую книгу, главу и стих',
    (tester) async {
      await prefs.setString(
        'bible_chapter_v1:Jn.3',
        '{"book":"Jn","number":3,"verses":[{"number":1,"text":"Первый стих Иоанна"},{"number":2,"text":"Сохранённый стих Иоанна"}]}',
      );
      await prefs.setString(
        'bible_progress_v1:Jn.3',
        '{"verse":2,"fraction":1}',
      );
      await prefs.setString('bible_last_chapter_v1', 'Jn.3');
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await tester.tap(tabIcon(CupertinoIcons.book));
      await settle(tester);
      expect(find.text('Сохранённый стих Иоанна'), findsOneWidget);
      expect(find.text('3:2'), findsOneWidget);
      await tester.tap(tabIcon(CupertinoIcons.sunset));
      await settle(tester);
      expect(find.byType(TodayScreen), findsOneWidget);
    },
  );

  testWidgets('стартует на «Главной» с кнопкой Мудрость дня', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    // Вариант А: дашборда между запуском и контентом нет вовсе.
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Мудрость дня'), findsOneWidget);
  });

  testWidgets('в навигации Главная, Библия и Профиль', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(tabIcon(CupertinoIcons.sunset_fill), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.text('Библия'),
      ),
      findsOneWidget,
    );
    expect(tabIcon(CupertinoIcons.bookmark), findsNothing);
    expect(tabIcon(CupertinoIcons.person), findsOneWidget);
  });

  testWidgets('в нижней навигации три вкладки без Планов', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    final labels = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(Text),
    );
    expect(
      tester.widgetList<Text>(labels).map((widget) => widget.data).toList(),
      ['Главная', 'Библия', 'Профиль'],
    );
    expect(ShellTab.values, hasLength(3));
  });

  testWidgets('стеклянная рамка плавно переезжает к выбранной вкладке', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    final selectionFinder = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(AnimatedPositioned),
    );
    expect(selectionFinder, findsOneWidget);

    final selection = tester.widget<AnimatedPositioned>(selectionFinder);
    final decoration =
        (selection.child as DecoratedBox).decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.borderRadius, BorderRadius.circular(25));

    final startLeft = tester.getRect(selectionFinder).left;
    await tester.tap(tabIcon(CupertinoIcons.person));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final movingLeft = tester.getRect(selectionFinder).left;
    await tester.pump(const Duration(milliseconds: 300));
    final endLeft = tester.getRect(selectionFinder).left;

    expect(movingLeft, greaterThan(startLeft));
    expect(movingLeft, lessThan(endLeft));
  });

  testWidgets('перетаскивание рамки выбирает вкладку под пальцем', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    final selectionFinder = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(AnimatedPositioned),
    );
    final startLeft = tester.getRect(selectionFinder).left;
    final gesture = await tester.startGesture(
      tester.getCenter(selectionFinder),
    );
    await gesture.moveBy(const Offset(500, 0));
    await tester.pump();

    expect(tester.getRect(selectionFinder).left, greaterThan(startLeft));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tabIcon(CupertinoIcons.person_fill), findsOneWidget);
  });

  testWidgets('на iOS навигацию рисует Flutter-капсула', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(buildApp());

      expect(find.byType(FloatingNavBar), findsOneWidget);
      expect(find.byType(UiKitView), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Мудрость дня открывается внутри Главной под навбаром', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(find.text('Мудрость дня'));
    await settle(tester);
    final wisdom = find.byType(DayWisdomScreen);
    expect(wisdom, findsOneWidget);
    expect(ModalRoute.of(tester.element(wisdom))!.fullscreenDialog, isFalse);
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(tabIcon(CupertinoIcons.sunset_fill), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await settle(tester);
    expect(find.byType(DayWisdomScreen), findsNothing);
    expect(find.text('Мудрость дня'), findsOneWidget);
  });

  testWidgets('кнопки Мудрости дня не уходят под навбар', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(find.text('Мудрость дня'));
    await settle(tester);
    final navTop = tester.getTopLeft(find.byType(FloatingNavBar)).dy;
    final share = find.ancestor(
      of: find.byIcon(CupertinoIcons.share),
      matching: find.byType(IconButton),
    );
    expect(share, findsOneWidget);
    expect(tester.getBottomLeft(share).dy, lessThanOrEqualTo(navTop));
  });

  testWidgets('Основы веры открываются внутри Главной под навбаром', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(find.byType(CourseProgressHeader));
    await settle(tester);
    final reader = find.byType(CourseReaderScreen);
    expect(reader, findsOneWidget);
    expect(ModalRoute.of(tester.element(reader))!.fullscreenDialog, isFalse);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });

  testWidgets('уход на другую вкладку сохраняет открытую Мудрость дня', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(find.text('Мудрость дня'));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.person));
    await settle(tester);
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.tap(tabIcon(CupertinoIcons.sunset));
    await settle(tester);
    expect(find.byType(DayWisdomScreen), findsOneWidget);
  });

  testWidgets('повторный тап по Главной возвращает к началу вкладки', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(platform: TargetPlatform.iOS));
    await settle(tester);
    await tester.tap(find.text('Мудрость дня'));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.sunset_fill));
    await settle(tester);
    expect(find.byType(DayWisdomScreen), findsNothing);
    expect(find.text('Мудрость дня'), findsOneWidget);
  });

  testWidgets('вход в курс с главной сразу открывает читалку', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    final plan = find.byType(CourseProgressHeader);
    expect(plan, findsOneWidget);
    await tester.tap(plan);
    await settle(tester);
    expect(find.byType(CourseReaderScreen), findsOneWidget);
    expect(find.text('О курсе'), findsNothing);
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await settle(tester);
    expect(plan, findsOneWidget);
  });

  testWidgets('начатый курс не увеличивает navbar и нижний отступ', (
    tester,
  ) async {
    await prefs.setString('course_progress_v4', '{"topic":1,"page":0}');
    await tester.pumpWidget(buildApp());
    await settle(tester);

    for (final label in ['Главная', 'Библия', 'Профиль']) {
      await tester.tap(
        find.descendant(
          of: find.byType(FloatingNavBar),
          matching: find.text(label),
        ),
      );
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(FloatingNavBar),
          matching: find.byType(CourseProgressHeader),
        ),
        findsNothing,
      );
      expect(
        tester.widget<FloatingNavInset>(find.byType(FloatingNavInset)).inset,
        kFloatingNavInset,
      );
    }
  });

  testWidgets('начатый курс продолжается с главной', (tester) async {
    await prefs.setString('course_progress_v4', '{"topic":3,"page":1}');
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await tester.tap(find.byType(CourseProgressHeader));
    await settle(tester);
    expect(find.byType(CourseReaderScreen), findsOneWidget);
    expect(find.text('Тема прочитана'), findsNothing);
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await settle(tester);
    expect(find.byType(CourseProgressHeader), findsOneWidget);
  });

  testWidgets('чистая установка активирует курс только при входе в читалку', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    final navbarCourse = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(CourseProgressHeader),
    );
    expect(navbarCourse, findsNothing);
    expect(prefs.getString('course_progress_v4'), isNull);
    final plan = find.byType(CourseProgressHeader);
    expect(prefs.getString('course_progress_v4'), isNull);
    await tester.tap(plan);
    await settle(tester);
    expect(find.byType(CourseReaderScreen), findsOneWidget);
    expect(prefs.getString('course_progress_v4'), isNotNull);
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await settle(tester);
    expect(navbarCourse, findsNothing);
    expect(plan, findsOneWidget);
  });

  testWidgets('подписи видны у всех вкладок, не только у активной', (
    tester,
  ) async {
    // Без ярлыков неочевидно, куда ведут иконки; активную вкладку отличает
    // акцентный цвет и насыщенность, а не наличие подписи.
    await tester.pumpWidget(buildApp());
    await settle(tester);

    for (final label in ['Главная', 'Библия', 'Профиль']) {
      expect(
        find.descendant(
          of: find.byType(FloatingNavBar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'нет подписи $label',
      );
    }
  });

  testWidgets('навигация плавает поверх контента, а не режет экран', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    // Глухая полоса снизу отрезала у экрана заметный кусок; теперь капсула
    // лежит в Stack над контентом и не сдвигает его вверх.
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.ancestor(
        of: find.byType(FloatingNavBar),
        matching: find.byType(Stack),
      ),
      findsWidgets,
    );

    // Мерим саму капсулу, а не FloatingNavBar: тот на всю ширину, отступы
    // и скругление живут внутри него.
    final capsule = tester.getRect(
      find
          .descendant(
            of: find.byType(FloatingNavBar),
            matching: find.byType(ClipRRect),
          )
          .first,
    );
    final screen = tester.getSize(find.byType(AppShell));
    expect(capsule.left, greaterThan(0), reason: 'капсула прижата к краю');
    expect(capsule.right, lessThan(screen.width));
    expect(
      capsule.bottom,
      lessThan(screen.height),
      reason: 'капсула не в самом низу',
    );
  });

  testWidgets('переключение вкладки открывает профиль', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);

    await tester.tap(tabIcon(CupertinoIcons.person));
    await settle(tester);
    // Тумблер «Тёмная тема» заменён выбором из трёх: система / светлая / тёмная.
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Система'), findsOneWidget);
  });

  testWidgets('копилка открывается из профиля и возвращается в него', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    expect(find.text('Закладки').hitTestable(), findsNothing);
    await tester.tap(tabIcon(CupertinoIcons.person));
    await settle(tester);
    final button = find.text('Закладки').hitTestable();
    expect(button, findsOneWidget);

    await tester.tap(button);
    await settle(tester);

    expect(find.byType(BookmarksScreen), findsOneWidget);
    final closeButton = find.descendant(
      of: find.byType(BookmarksScreen),
      matching: find.byType(BackButton),
    );
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await settle(tester);

    expect(find.byType(BookmarksScreen), findsNothing);
    expect(find.text('Закладки').hitTestable(), findsOneWidget);
    expect(find.text('Тема').hitTestable(), findsOneWidget);
  });

  testWidgets('выбранная дата переживает уход на другую вкладку', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
        dayProgressRepositoryProvider.overrideWithValue(
          _FakeProgressRepository(),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const AppShell()),
      ),
    );
    await settle(tester);

    final other = DateTime.now().subtract(const Duration(days: 3));
    container.read(selectedDateProvider.notifier).select(other);
    await settle(tester);

    await tester.tap(tabIcon(CupertinoIcons.person));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.sunset));
    await settle(tester);

    expect(dateKey(container.read(selectedDateProvider)), dateKey(other));
  });

  testWidgets('selectedTabProvider переключает вкладку снаружи', (
    tester,
  ) async {
    // На этом держится FR-015: тап по пушу обязан открыть «Главную»,
    // где бы юзер ни был в прошлый раз.
    await prefs.setString(
      'bible_chapter_v1:Mt.1',
      '{"book":"Mt","number":1,"verses":[{"number":1,"text":"Первый стих Матфея"}]}',
    );
    final container = ProviderContainer(
      overrides: [
        dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
        dayProgressRepositoryProvider.overrideWithValue(
          _FakeProgressRepository(),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const AppShell()),
      ),
    );
    await settle(tester);

    container.read(selectedTabProvider.notifier).select(ShellTab.profile);
    await settle(tester);
    expect(find.byType(ProfileScreen), findsOneWidget);

    container.read(selectedTabProvider.notifier).select(ShellTab.today);
    await settle(tester);
    expect(find.text('Мудрость дня'), findsOneWidget);

    container.read(selectedTabProvider.notifier).select(ShellTab.bible);
    await settle(tester);
    expect(find.byType(BibleTabScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Книги и главы'));
    await settle(tester);
    container.read(selectedTabProvider.notifier).select(ShellTab.today);
    await settle(tester);
    expect(find.byType(BibleTabScreen), findsNothing);
    expect(find.text('Новый Завет'), findsNothing);
    expect(find.text('Мудрость дня'), findsOneWidget);
  });
}
