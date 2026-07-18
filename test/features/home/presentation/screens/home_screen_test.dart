// test/features/home/presentation/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/result/result.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/theme/theme_mode_provider.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_cards_repository.dart';
import 'package:lampada/features/daily_cards/domain/repositories/day_progress_repository.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/home/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCardsRepository implements DayCardsRepository {
  @override
  Future<Result<List<DayCard>>> getCardsFor(DateTime date) async => Success([
        const DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
        const DayCard(id: 'a', type: CardType.advice, body: 'b', source: 's'),
        const DayCard(id: 'ba', type: CardType.basics, body: 'b', source: 's'),
        const DayCard(id: 'r', type: CardType.reading, body: 'b', source: 's'),
      ]);
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
  @override
  Future<Result<DayProgress>> resetToday() async => Success(_progress);
}

/// Мини-копия `LampadaApp` — та же связка `theme`/`darkTheme`/`themeMode`
/// через `themeModeProvider`, что и в проде, чтобы тесты реально проверяли
/// связку провайдера с MaterialApp, а не подменяли её захардкоженным флагом.
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
    return ProviderScope(
      overrides: [
        dayCardsRepositoryProvider.overrideWithValue(_FakeCardsRepository()),
        dayProgressRepositoryProvider
            .overrideWithValue(_FakeProgressRepository(progress)),
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

    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('Текущая серия 12 дней'), findsOneWidget);
    expect(find.text('Цитата'), findsOneWidget);
  });

  testWidgets('серия 0 — «Начните сессию» вместо «0 дней»', (tester) async {
    await tester.pumpWidget(
      await buildApp(const DayProgress(readTypes: {}, streakDays: 0)),
    );
    await tester.pump();

    expect(find.text('Начните сессию'), findsOneWidget);
    expect(find.textContaining('0 дней'), findsNothing);
  });

  testWidgets('часть прочитана — CTA «Продолжить»', (tester) async {
    await tester.pumpWidget(
      await buildApp(
        const DayProgress(readTypes: {CardType.quote}, streakDays: 3),
      ),
    );
    await tester.pump();

    expect(find.text('Продолжить'), findsOneWidget);
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
          },
          streakDays: 5,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Пройти снова'), findsOneWidget);
    expect(find.text('Начать'), findsNothing);
    expect(find.text('Продолжить'), findsNothing);
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

    expect(find.text('Начать'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    final context = tester.element(find.text('Начать'));
    expect(Theme.of(context).brightness, Brightness.dark);

    final chipText = tester.widget<Text>(find.text('Цитата'));
    expect(chipText.style?.color, AppColorsExtension.dark.chipUnreadText);
  });

  testWidgets('тумблер темы циклит system → light → dark на тап',
      (tester) async {
    await tester.pumpWidget(
      await buildApp(const DayProgress(readTypes: {}, streakDays: 1)),
    );
    await tester.pump();

    expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.brightness_auto_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
