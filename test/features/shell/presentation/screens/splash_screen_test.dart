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
import 'package:lampada/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:lampada/features/shell/presentation/screens/app_shell.dart';
import 'package:lampada/features/shell/presentation/screens/splash_screen.dart';
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

  @override
  Future<Result<DayProgress>> loadToday() async =>
      Success(DayProgress(readTypes: _read, visitedDays: _visited));

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    _read = {..._read, type};
    _visited = {..._visited, dateKey(DateTime.now())};
    return Success(DayProgress(readTypes: _read, visitedDays: _visited));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Widget app(SharedPreferences prefs) => ProviderScope(
    overrides: [
      dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
      dayProgressRepositoryProvider.overrideWithValue(
        _FakeProgressRepository(),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
  );

  /// Сплэш держит брендинг минимум 700мс и уходит анимацией на 600мс.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('первый запуск ведёт на приветствие, а не сразу в шелл', (
    tester,
  ) async {
    await tester.pumpWidget(app(await prefsWith({})));
    await settle(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('кнопка приветствия открывает день', (tester) async {
    // Регрессия: колбэк держал контекст сплэша, а тот после pushReplacement
    // размонтирован. Тап бросал «This widget has been unmounted», и снаружи
    // кнопка выглядела молчащей. Тест приветствия в одиночку это пропускал —
    // там колбэк был заглушкой.
    final prefs = await prefsWith({});
    await tester.pumpWidget(app(prefs));
    await settle(tester);

    await tester.tap(find.text('Открыть сегодняшний день'));
    await settle(tester);

    // skipOffstage: false — «Сегодня» тут же само открывает первую карточку
    // отдельным маршрутом, и шелл уходит за кадр. Нам важно, что он в дереве.
    expect(find.byType(AppShell, skipOffstage: false), findsOneWidget);
    // Приветствие именно УДАЛЕНО из дерева: pushReplacement, а не push.
    expect(find.byType(WelcomeScreen, skipOffstage: false), findsNothing);
    expect(prefs.getBool('onboarding_shown'), isTrue);
  });

  testWidgets('второй запуск приветствие пропускает', (tester) async {
    final prefs = await prefsWith({'flutter.onboarding_shown': true});
    await tester.pumpWidget(app(prefs));
    await settle(tester);

    expect(find.byType(WelcomeScreen, skipOffstage: false), findsNothing);
    expect(find.byType(AppShell, skipOffstage: false), findsOneWidget);
  });
}
