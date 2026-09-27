import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_reader_screen.dart';
import 'package:lampada/features/daily_cards/presentation/screens/today_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_progress_header.dart';
import 'package:lampada/features/profile/presentation/screens/profile_screen.dart';
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
  /// настройку темы уже на старте — prefs нужны даже тесту про «Домой».
  Widget buildApp({
    DayCard? topic,
    DayProgressRepository? progress,
    Future<DayCard?> Function()? loadTopic,
  }) => ProviderScope(
    overrides: [
      if (loadTopic != null)
        courseTopicProvider.overrideWith((ref) => loadTopic()),
      if (topic != null) courseTopicProvider.overrideWith((ref) async => topic),
      dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
      dayProgressRepositoryProvider.overrideWithValue(
        progress ?? _FakeProgressRepository(),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const AppShell()),
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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// «Домой» сама открывает первую непрочитанную карточку на весь экран,
  /// и она перекрывает таб-бар — тестам про навигацию её надо закрыть.
  Future<void> dismissAutoOpened(WidgetTester tester) async {
    if (find.byIcon(CupertinoIcons.arrow_left).evaluate().isEmpty) return;
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await settle(tester);
  }

  testWidgets('стартует на «Домой» — карточка, а не экран-прослойка', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);

    // Вариант А: дашборда между запуском и контентом нет вовсе.
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Мысль дня'), findsOneWidget);
  });

  testWidgets('в навигации четыре вкладки: Домой, Библия, Планы, Профиль', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);

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

  testWidgets('стеклянная рамка плавно переезжает к выбранной вкладке', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);

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
    await dismissAutoOpened(tester);

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

  testWidgets('вход из списка планов открывает страницу курса', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.text('Планы'),
      ),
    );
    await settle(tester);
    final plan = find.byWidgetPredicate(
      (widget) => widget is CourseProgressHeader && !widget.compact,
    );
    expect(plan, findsOneWidget);
    await tester.tap(plan);
    await settle(tester);
    expect(find.byType(CourseReaderScreen), findsNothing);
    expect(find.text('О курсе'), findsOneWidget);
    await tester.tap(find.text('Начать'));
    await settle(tester);
    expect(find.byType(CourseReaderScreen), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await settle(tester);
    expect(find.text('О курсе'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(plan, findsOneWidget);
  });

  testWidgets(
    'обёртка курса видна на каждой вкладке и открывает читалку напрямую',
    (tester) async {
      await prefs.setString('course_progress_v4', '{"topic":1,"page":0}');
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);
      final header = find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.byType(CourseProgressHeader),
      );
      for (final label in ['Домой', 'Библия', 'Планы', 'Профиль']) {
        await tester.tap(
          find.descendant(
            of: find.byType(FloatingNavBar),
            matching: find.text(label),
          ),
        );
        await settle(tester);
        expect(header, findsOneWidget);
        expect(
          find.descendant(
            of: header,
            matching: find.text('ОСНОВЫ ВЕРЫ №1/365'),
          ),
          findsOneWidget,
        );
        await tester.tap(header);
        await settle(tester);
        expect(find.byType(CourseReaderScreen), findsOneWidget);
        expect(find.text('О курсе'), findsNothing);
        await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
        await settle(tester);
        expect(header, findsOneWidget);
      }
    },
  );

  testWidgets(
    'обёртка показывает прогресс темы и скрывается после завершения',
    (tester) async {
      await prefs.setString(
        'course_progress_v4',
        '{"topic":3,"completedTopics":[1,2]}',
      );
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);
      final header = find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.byType(CourseProgressHeader),
      );
      expect(
        find.descendant(of: header, matching: find.text('ОСНОВЫ ВЕРЫ №3/365')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.descendant(
                of: header,
                matching: find.byType(LinearProgressIndicator),
              ),
            )
            .value,
        closeTo(1 / 2, 0.000001),
      );
      await tester.tap(header);
      await settle(tester);
      expect(find.text('Основы веры · Тема №3'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await settle(tester);
      expect(find.text('Тема прочитана'), findsOneWidget);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
      await settle(tester);
      expect(header, findsNothing);
      expect(find.byType(FloatingNavBar), findsOneWidget);
      expect(
        tester.widget<FloatingNavInset>(find.byType(FloatingNavInset)).inset,
        kFloatingNavInset,
      );
    },
  );

  testWidgets('быстрый вход восстанавливает страницу и сохраняет новое место', (
    tester,
  ) async {
    await prefs.setString('course_progress_v4', '{"topic":3,"page":1}');
    const topic = DayCard(
      id: 'basics-topic-3',
      type: CardType.basics,
      body: 'Первое. Второе. Третье.',
      source: 'Источник',
    );
    await tester.pumpWidget(buildApp(topic: topic));
    await settle(tester);
    await dismissAutoOpened(tester);
    final header = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(CourseProgressHeader),
    );
    expect(
      find.descendant(of: header, matching: find.text('ОСНОВЫ ВЕРЫ №3/365')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: header, matching: find.text('Прочитано 2/4')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: header,
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value,
      closeTo(2 / 4, 0.000001),
    );
    await tester.tap(header);
    await settle(tester);
    expect(find.text('Прочитано 0 из 365'), findsNothing);
    expect(find.text('Второе.'), findsOneWidget);
    expect(find.text('Первое.'), findsNothing);
    await tester.drag(find.byType(PageView), const Offset(0, -500));
    await settle(tester);
    expect(find.text('Третье.'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await settle(tester);
    expect(
      find.descendant(of: header, matching: find.text('Прочитано 3/4')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: header,
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value,
      closeTo(3 / 4, 0.000001),
    );
    await tester.tap(header);
    await settle(tester);
    expect(find.text('Третье.'), findsOneWidget);
    expect(find.text('Второе.'), findsNothing);
  });

  testWidgets(
    'возврат на финальную страницу завершает прерванную запись прохождения',
    (tester) async {
      await prefs.setString('course_progress_v4', '{"topic":3,"page":1}');
      await tester.pumpWidget(buildApp());
      await settle(tester);
      await dismissAutoOpened(tester);
      final header = find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.byType(CourseProgressHeader),
      );
      await tester.tap(header);
      await settle(tester);
      expect(find.text('Тема прочитана'), findsOneWidget);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
      await settle(tester);
      expect(header, findsNothing);
    },
  );

  testWidgets('обёртка скрыта только после темы за сегодняшний день', (
    tester,
  ) async {
    await prefs.setString('course_progress_v4', '{"topic":3,"page":0}');
    final progress = _FakeProgressRepository();
    await progress.markRead(
      CardType.basics,
      date: DateTime.now().subtract(const Duration(days: 1)),
    );
    await tester.pumpWidget(buildApp(progress: progress));
    await settle(tester);
    await dismissAutoOpened(tester);
    final header = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(CourseProgressHeader),
    );
    expect(header, findsOneWidget);
    await progress.markRead(CardType.basics);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    container.invalidate(dayProgressProvider);
    await settle(tester);
    expect(header, findsNothing);
    for (final label in ['Библия', 'Планы', 'Профиль']) {
      await tester.tap(
        find.descendant(
          of: find.byType(FloatingNavBar),
          matching: find.text(label),
        ),
      );
      await settle(tester);
      expect(header, findsNothing);
    }
  });

  testWidgets('готовая финальная карточка не отмечает новый день повторно', (
    tester,
  ) async {
    await prefs.setString(
      'course_progress_v4',
      '{"topic":3,"page":1,"completedTopics":[3]}',
    );
    final progress = _FakeProgressRepository();
    await tester.pumpWidget(buildApp(progress: progress));
    await settle(tester);
    await dismissAutoOpened(tester);
    final header = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(CourseProgressHeader),
    );
    await tester.tap(header);
    await settle(tester);
    expect(find.text('Тема прочитана'), findsOneWidget);
    expect(
      (await progress.loadToday() as Success<DayProgress>).value.readTypes,
      isNot(contains(CardType.basics)),
    );
  });

  testWidgets('повторный вход ждёт актуальную тему вместо старой карточки', (
    tester,
  ) async {
    const third = DayCard(
      id: 'basics-topic-3',
      type: CardType.basics,
      body: 'Третья тема.',
      source: 'Источник',
    );
    const fourth = DayCard(
      id: 'basics-topic-4',
      type: CardType.basics,
      body: 'Четвёртая тема.',
      source: 'Источник',
    );
    Future<DayCard?> response = Future.value(third);
    await prefs.setString('course_progress_v4', '{"topic":3,"page":0}');
    await tester.pumpWidget(buildApp(loadTopic: () => response));
    await settle(tester);
    await dismissAutoOpened(tester);
    final pending = Completer<DayCard?>();
    response = pending.future;
    await prefs.setString('course_progress_v4', '{"topic":4,"page":1}');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    container.invalidate(courseTopicProvider);
    await tester.pump();
    final header = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(CourseProgressHeader),
    );
    await tester.tap(header);
    await tester.pump();
    expect(find.byType(CourseReaderScreen), findsNothing);
    pending.complete(fourth);
    await settle(tester);
    expect(find.text('Основы веры · Тема №4'), findsOneWidget);
    expect(find.text('Тема прочитана'), findsOneWidget);
  });

  testWidgets('чистая установка не активирует план до нажатия Начать', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);
    final header = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(CourseProgressHeader),
    );
    expect(header, findsNothing);
    expect(prefs.getString('course_progress_v4'), isNull);
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.text('Планы'),
      ),
    );
    await settle(tester);
    final plan = find.byWidgetPredicate(
      (widget) => widget is CourseProgressHeader && !widget.compact,
    );
    await tester.tap(plan);
    await settle(tester);
    expect(find.text('О курсе'), findsOneWidget);
    expect(prefs.getString('course_progress_v4'), isNull);
    await tester.tap(find.text('Начать'));
    await settle(tester);
    expect(find.byType(CourseReaderScreen), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.arrow_left));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(header, findsOneWidget);
    expect(
      find.descendant(of: header, matching: find.text('ОСНОВЫ ВЕРЫ №1/365')),
      findsOneWidget,
    );
  });

  testWidgets('подписи видны у всех вкладок, не только у активной', (
    tester,
  ) async {
    // Без ярлыков неочевидно, куда ведут иконки; активную вкладку отличает
    // акцентный цвет и насыщенность, а не наличие подписи.
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);

    for (final label in ['Домой', 'Библия', 'Планы', 'Профиль']) {
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
    await dismissAutoOpened(tester);

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
    await dismissAutoOpened(tester);

    await tester.tap(tabIcon(CupertinoIcons.person));
    await settle(tester);
    await dismissAutoOpened(tester);
    // Тумблер «Тёмная тема» заменён выбором из трёх: система / светлая / тёмная.
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Система'), findsOneWidget);
  });

  testWidgets('копилка открывается из профиля и возвращается в него', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);
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
    await dismissAutoOpened(tester);

    final other = DateTime.now().subtract(const Duration(days: 3));
    container.read(selectedDateProvider.notifier).select(other);
    await settle(tester);
    await dismissAutoOpened(tester);

    await tester.tap(tabIcon(CupertinoIcons.person));
    await settle(tester);
    await tester.tap(tabIcon(CupertinoIcons.sunset));
    await settle(tester);
    await dismissAutoOpened(tester);

    expect(dateKey(container.read(selectedDateProvider)), dateKey(other));
  });

  testWidgets('selectedTabProvider переключает вкладку снаружи', (
    tester,
  ) async {
    // На этом держится FR-015: тап по пушу обязан открыть «Домой»,
    // где бы юзер ни был в прошлый раз.
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
    await dismissAutoOpened(tester);

    container.read(selectedTabProvider.notifier).select(ShellTab.profile);
    await settle(tester);
    await dismissAutoOpened(tester);
    expect(find.byType(ProfileScreen), findsOneWidget);

    container.read(selectedTabProvider.notifier).select(ShellTab.today);
    await settle(tester);
    await dismissAutoOpened(tester);
    expect(find.text('Мысль дня'), findsOneWidget);
  });
}
