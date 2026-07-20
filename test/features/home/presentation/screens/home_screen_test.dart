import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/theme/theme_mode_provider.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/daily_card_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/streak_label.dart';
import 'package:lampada/features/home/presentation/screens/home_screen.dart';
import 'package:lampada/features/home/presentation/widgets/home_cta_buttons.dart';
import 'package:lampada/features/home/presentation/widgets/home_offline_view.dart';
import 'package:lampada/features/home/presentation/widgets/home_subtitle_empty.dart';
import 'package:lampada/features/home/presentation/widgets/stale_cache_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async =>
      Success(TodayCards(cards: const [
        DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
        DayCard(id: 'a', type: CardType.advice, body: 'b', source: 's'),
        DayCard(id: 'ba', type: CardType.basics, body: 'b', source: 's'),
        DayCard(id: 'r', type: CardType.reading, body: 'b', source: 's'),
        DayCard(id: 'qu', type: CardType.question, body: 'b', source: 's'),
      ]));
}

class _FakeProgressRepository implements DayProgressRepository {
  _FakeProgressRepository(this._progress);
  final DayProgress _progress;

  @override
  Future<Result<DayProgress>> loadToday() async => Success(_progress);
  @override
  Future<Result<DayProgress>> markRead(CardType type) async =>
      Success(_progress);
  @override
  Future<Result<DayProgress>> completeDay() async => Success(_progress);
}

class _FailingCardsRepository implements DayCardsRepository {
  _FailingCardsRepository(this.kind);
  final FailureKind kind;

  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async =>
      Failure(AppFailure('нет карточек', kind: kind));
}

class _StaleCardsRepository implements DayCardsRepository {
  @override
  Future<Result<TodayCards>> getCardsFor(DateTime date) async => Success(
        TodayCards(
          cards: const [
            DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
            DayCard(id: 'a', type: CardType.advice, body: 'b', source: 's'),
            DayCard(id: 'ba', type: CardType.basics, body: 'b', source: 's'),
            DayCard(id: 'r', type: CardType.reading, body: 'b', source: 's'),
            DayCard(id: 'qu', type: CardType.question, body: 'b', source: 's'),
          ],
          staleDate: DateTime(2026, 7, 19),
        ),
      );
}

/// Мини-копия `LampadaApp`: та же связка `theme`/`darkTheme`/`themeMode`
/// через `themeModeProvider`, что и в проде — не хардкодим флаг темы.
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: const HomeScreen(),
    );
  }
}

void main() {
  Future<Widget> buildApp(
    DayProgress progress, {
    String? initialThemeMode,
  }) async {
    SharedPreferences.setMockInitialValues(
      initialThemeMode == null ? {} : {'theme_mode': initialThemeMode},
    );
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
        dayProgressRepositoryProvider
            .overrideWithValue(_FakeProgressRepository(progress)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    // Прогреваем провайдеры до первого build, чтобы тест сразу видел готовый
    // Home, а не кадр загрузки. Для падающего провайдера так нельзя — см.
    // buildOfflineApp.
    await container.read(todayCardsProvider.future);
    await container.read(dayProgressProvider.future);
    return UncontrolledProviderScope(
      container: container,
      child: const _TestApp(),
    );
  }

  /// Без прогрева: у падающего провайдера `todayCardsProvider.future` не
  /// резолвится вовсе, и прогрев повесил бы тест. Пампим и даём провайдеру
  /// самому пройти loading → error.
  Future<Widget> buildOfflineApp(FailureKind kind) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        dayCardsRepositoryProvider
            .overrideWithValue(_FailingCardsRepository(kind)),
        dayProgressRepositoryProvider.overrideWithValue(
          _FakeProgressRepository(
            const DayProgress(readTypes: {}, streakDays: 0),
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const _TestApp(),
    );
  }

  testWidgets('ничего не прочитано — CTA «Начать» и серия', (tester) async {
    await tester.pumpWidget(
      await buildApp(const DayProgress(readTypes: {}, streakDays: 12)),
    );
    await tester.pump();

    expect(find.byType(HomeStartButton), findsOneWidget);
    final streak = tester.widget<StreakLabel>(find.byType(StreakLabel));
    expect(streak.days, 12);
    expect(find.byKey(const ValueKey(CardType.quote)), findsOneWidget);
  });

  testWidgets('серия 0 — «Начните сессию» вместо «0 дней»', (tester) async {
    await tester.pumpWidget(
      await buildApp(const DayProgress(readTypes: {}, streakDays: 0)),
    );
    await tester.pump();

    expect(find.byType(HomeSubtitleEmpty), findsOneWidget);
    expect(find.byType(StreakLabel), findsNothing);
  });

  testWidgets('часть прочитана — CTA «Продолжить»', (tester) async {
    await tester.pumpWidget(
      await buildApp(
        const DayProgress(readTypes: {CardType.quote}, streakDays: 3),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeContinueButton), findsOneWidget);
  });

  testWidgets('всё прочитано — «Пройти снова», без CTA', (tester) async {
    await tester.pumpWidget(
      await buildApp(
        const DayProgress(
          readTypes: {
            CardType.quote,
            CardType.advice,
            CardType.basics,
            CardType.reading,
            CardType.question,
          },
          streakDays: 5,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeReplayButton), findsOneWidget);
    expect(find.byType(HomeStartButton), findsNothing);
    expect(find.byType(HomeContinueButton), findsNothing);
  });

  testWidgets('«Пройти снова» открывает карточки, прогресс не сбрасывает',
      (tester) async {
    const allRead = DayProgress(
      readTypes: {
        CardType.quote,
        CardType.advice,
        CardType.basics,
        CardType.reading,
        CardType.question,
      },
      streakDays: 5,
    );
    await tester.pumpWidget(await buildApp(allRead));
    await tester.pump();

    await tester.tap(find.byType(HomeReplayButton));
    // LampadaMark крутится бесконечно — pumpAndSettle не осядет,
    // прокачиваем ровно на длительность перехода/анимации карточки.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(DailyCardScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(DailyCardScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(HomeReplayButton), findsOneWidget);
    expect(find.byType(HomeStartButton), findsNothing);
    expect(find.byType(HomeContinueButton), findsNothing);
  });

  testWidgets(
      'тёмная тема (из shared_preferences) — экран строится, цвета из dark-палитры',
      (tester) async {
    await tester.pumpWidget(
      await buildApp(
        const DayProgress(readTypes: {}, streakDays: 1),
        initialThemeMode: 'dark',
      ),
    );
    await tester.pump();

    expect(find.byType(HomeStartButton), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    final context = tester.element(find.byType(HomeStartButton));
    expect(Theme.of(context).brightness, Brightness.dark);

    final chipText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey(CardType.quote)),
        matching: find.byType(Text),
      ),
    );
    expect(chipText.style?.color, AppColorsExtension.dark.chipUnreadText);
  });

  testWidgets('тумблер темы переключает light ↔ dark на тап', (tester) async {
    tester.view.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    addTearDown(
      tester.view.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    await tester.pumpWidget(
      await buildApp(const DayProgress(readTypes: {}, streakDays: 1)),
    );
    await tester.pump();

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });

  testWidgets('нет сети и кэша пуст — офлайн-вид с советом про Wi-Fi',
      (tester) async {
    await tester.pumpWidget(await buildOfflineApp(FailureKind.network));
    await tester.pump();
    await tester.pump();

    expect(find.byType(HomeOfflineView), findsOneWidget);
    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    expect(find.text('Включите Wi-Fi или мобильную сеть'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.byType(HomeStartButton), findsNothing);
  });

  testWidgets('сервер лёг — текст про Азбуку, без совета включить Wi-Fi',
      (tester) async {
    await tester.pumpWidget(await buildOfflineApp(FailureKind.server));
    await tester.pump();
    await tester.pump();

    expect(find.text('Азбука веры сейчас недоступна'), findsOneWidget);
    expect(find.text('Включите Wi-Fi или мобильную сеть'), findsNothing);
  });

  testWidgets('«Повторить» перезапрашивает карточки', (tester) async {
    await tester.pumpWidget(await buildOfflineApp(FailureKind.network));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Повторить'));
    await tester.pump();
    await tester.pump();

    // Репозиторий по-прежнему падает — офлайн-вид остаётся, без крешей.
    expect(find.byType(HomeOfflineView), findsOneWidget);
  });

  testWidgets('кэш за другую дату — пометка «Офлайн», Home остаётся полным',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        dayCardsRepositoryProvider.overrideWithValue(_StaleCardsRepository()),
        dayProgressRepositoryProvider.overrideWithValue(
          _FakeProgressRepository(
            const DayProgress(readTypes: {}, streakDays: 4),
          ),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    await container.read(todayCardsProvider.future);
    await container.read(dayProgressProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _TestApp()),
    );
    await tester.pump();

    expect(find.byType(StaleCacheNotice), findsOneWidget);
    expect(find.text('Офлайн · карточки за 19 июля'), findsOneWidget);
    expect(find.byType(HomeStartButton), findsOneWidget);
    expect(find.byKey(const ValueKey(CardType.quote)), findsOneWidget);
  });
}
