import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/onboarding/presentation/providers/providers.dart';
import 'package:lampada/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app({void Function(BuildContext)? onStart}) => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: WelcomeScreen(onStart: onStart ?? (_) {}),
    ),
  );

  testWidgets('говорит, куда человек попал, а не как устроено приложение', (
    tester,
  ) async {
    // Персона боится не длинных текстов, а того, что «это не для неё» и что
    // будет непонятно. Экран отвечает на это, а не рекламирует дозировку:
    // про «одну мысль за раз» тут не должно быть ни слова — это наша
    // механика, и показать её следующим экраном убедительнее, чем обещать.
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('Лампада'), findsOneWidget);
    expect(
      find.text('Для тех, кто только начал ходить в церковь'),
      findsOneWidget,
    );
    expect(find.textContaining('отрывок Евангелия с толкованием'), findsOne);
    expect(find.textContaining('Основы веры'), findsOne);
  });

  testWidgets('не обещает дозировку словами', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    for (final banned in ['одной мысли', 'за раз', 'вместо ленты', '5 минут']) {
      expect(
        find.textContaining(banned),
        findsNothing,
        reason: 'на экране осталась реклама механики: $banned',
      );
    }
  });

  testWidgets('кнопка запускает день и помечает приветствие показанным', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(app(onStart: (_) => started = true));
    await tester.pump();

    await tester.tap(find.text('Открыть сегодняшний день'));
    await tester.pump();

    expect(started, isTrue);
    // Иначе приветствие встречало бы юзера каждый запуск.
    expect(prefs.getBool('onboarding_shown'), isTrue);
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
