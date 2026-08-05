import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/format/date_key.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/today_screen.dart';
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
      ],
    ),
  );
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// IndexedStack строит все четыре вкладки сразу, поэтому Профиль читает
  /// настройку темы уже на старте — prefs нужны даже тесту про «Сегодня».
  Widget buildApp() => ProviderScope(
    overrides: [
      dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
      dayProgressRepositoryProvider.overrideWithValue(
        _FakeProgressRepository(),
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

  /// «Сегодня» сама открывает первую непрочитанную карточку на весь экран,
  /// и она перекрывает таб-бар — тестам про навигацию её надо закрыть.
  Future<void> dismissAutoOpened(WidgetTester tester) async {
    if (find.byIcon(Icons.close).evaluate().isEmpty) return;
    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);
  }

  testWidgets('стартует на «Сегодня» — карточка, а не экран-прослойка', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);

    // Вариант А: дашборда между запуском и контентом нет вовсе.
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Мысль дня'), findsOneWidget);
  });

  testWidgets('в навигации три вкладки: календарь свёрнут в полоску недели', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);

    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(tabIcon(Icons.wb_twilight), findsOneWidget);
    expect(tabIcon(Icons.bookmark_border), findsOneWidget);
    expect(tabIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('подписи видны у всех вкладок, не только у активной', (
    tester,
  ) async {
    // Без ярлыков неочевидно, куда ведут иконки; активную вкладку отличает
    // акцентный цвет и насыщенность, а не наличие подписи.
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);

    for (final label in ['Сегодня', 'Закладки', 'Профиль']) {
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

  testWidgets('переключение вкладки меняет содержимое', (tester) async {
    await tester.pumpWidget(buildApp());
    await settle(tester);
    await dismissAutoOpened(tester);

    await tester.tap(tabIcon(Icons.person_outline));
    await settle(tester);
    await dismissAutoOpened(tester);
    // Тумблер «Тёмная тема» заменён выбором из трёх: система / светлая / тёмная.
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Система'), findsOneWidget);

    await tester.tap(tabIcon(Icons.bookmark_border));
    await settle(tester);
    await dismissAutoOpened(tester);
    expect(find.byType(BookmarksScreen), findsOneWidget);
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

    await tester.tap(tabIcon(Icons.bookmark_border));
    await settle(tester);
    await dismissAutoOpened(tester);
    await tester.tap(tabIcon(Icons.wb_twilight_outlined));
    await settle(tester);
    await dismissAutoOpened(tester);

    expect(dateKey(container.read(selectedDateProvider)), dateKey(other));
  });

  testWidgets('selectedTabProvider переключает вкладку снаружи', (
    tester,
  ) async {
    // На этом держится FR-015: тап по пушу обязан открыть «Сегодня»,
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
