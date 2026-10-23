import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/onboarding/presentation/providers/providers.dart';
import 'package:lampada/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeAnalytics analytics;

  setUp(() async {
    analytics = FakeAnalytics();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app({void Function(BuildContext)? onStart}) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      analyticsProvider.overrideWithValue(analytics),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: WelcomeScreen(onStart: onStart ?? (_) {}),
    ),
  );

  Future<void> goToSecondStep(WidgetTester tester) async {
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
  }

  testWidgets('первый шаг говорит о времени в ленте без упрёка', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.textContaining('проводим в соцсетях'), findsOneWidget);
    expect(find.textContaining('стали меньше скроллить ленту'), findsOneWidget);
    expect(find.text('Продолжить'), findsOneWidget);
    expect(find.text('Открыть сегодняшний день'), findsNothing);
  });

  testWidgets('«Продолжить» ведёт ко второму шагу, а не в приложение', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(app(onStart: (_) => started = true));
    await tester.pump();

    await goToSecondStep(tester);

    expect(find.textContaining('пищей для'), findsOne);
    expect(find.text('Открыть сегодняшний день'), findsOneWidget);
    expect(started, isFalse);
    expect(prefs.getBool('onboarding_shown'), isNull);
  });

  testWidgets('системный «назад» на втором шаге возвращает к первому', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await goToSecondStep(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Продолжить'), findsOneWidget);
  });

  testWidgets('кнопка запускает день и помечает приветствие показанным', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(app(onStart: (_) => started = true));
    await tester.pump();
    await goToSecondStep(tester);

    await tester.tap(find.text('Открыть сегодняшний день'));
    await tester.pump();

    expect(started, isTrue);
    // Иначе приветствие встречало бы юзера каждый запуск.
    expect(prefs.getBool('onboarding_shown'), isTrue);
  });

  testWidgets('аналитика видит каждый шаг и завершение', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    expect(analytics.names, ['onboarding_step_viewed']);
    expect(analytics.single('onboarding_step_viewed'), {'step': 'time'});

    await goToSecondStep(tester);
    expect(
      analytics.events
          .where((e) => e.name == 'onboarding_step_viewed')
          .map((e) => e.params['step']),
      ['time', 'reader'],
    );

    await tester.tap(find.text('Открыть сегодняшний день'));
    await tester.pump();
    expect(analytics.names, contains('onboarding_completed'));
  });

  testWidgets('повторно приветствие не показывается', (tester) async {
    SharedPreferences.setMockInitialValues({'flutter.onboarding_shown': true});
    final seen = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(seen)],
    );
    addTearDown(container.dispose);

    expect(await container.read(onboardingShownProvider.future), isTrue);
  });
}
