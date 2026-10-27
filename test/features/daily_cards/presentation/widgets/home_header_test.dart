import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_header.dart';

import '../../../../support/haptics.dart';
import 'frosted_fade_expectations.dart';

Finder _lamp(String state) =>
    find.image(AssetImage('assets/illustrations/lampada_$state.png'));

void main() {
  group('приветствие по времени суток', () {
    String at(int hour, [int minute = 0]) =>
        greetingFor(DateTime(2026, 10, 22, hour, minute));

    test('утро с 4:00 до полудня', () {
      expect(at(4), 'Доброе утро!');
      expect(at(8, 30), 'Доброе утро!');
      expect(at(11, 59), 'Доброе утро!');
    });

    test('день с полудня до 18:00', () {
      expect(at(12), 'Добрый день!');
      expect(at(17, 59), 'Добрый день!');
    });

    test('вечер с 18:00 и до 4:00 следующего утра', () {
      // «Доброй ночи» по-русски прощание, поэтому ночью продолжается вечер.
      expect(at(18), 'Добрый вечер!');
      expect(at(23, 59), 'Добрый вечер!');
      expect(at(0), 'Добрый вечер!');
      expect(at(3, 59), 'Добрый вечер!');
    });
  });

  Widget app({
    required int? streak,
    VoidCallback? onStreakTap,
    ThemeData? theme,
  }) => MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Scaffold(
      body: HomeHeader(
        now: DateTime(2026, 10, 22, 6, 16),
        streak: streak,
        onStreakTap: onStreakTap ?? () {},
      ),
    ),
  );

  testWidgets('шапка показывает приветствие, лампаду и число серии', (
    tester,
  ) async {
    await tester.pumpWidget(app(streak: 3));

    expect(find.text('Доброе утро!'), findsOneWidget);
    // Приветствие набрано той же гарнитурой, что названия плиток ниже.
    expect(
      tester.widget<Text>(find.text('Доброе утро!')).style?.fontFamily,
      'Lora',
    );
    // Дата и пост в шапке больше не показываются.
    expect(find.text('Сегодня'), findsNothing);
    expect(find.textContaining('октября', findRichText: true), findsNothing);
    expect(find.textContaining('Постный', findRichText: true), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(_lamp('on'), findsOneWidget);
    expect(find.bySemanticsLabel('Лампадка: 3 дня подряд'), findsOneWidget);
  });

  testWidgets('без серии лампада в шапке погашена', (tester) async {
    await tester.pumpWidget(app(streak: 0, theme: AppTheme.dark));

    expect(find.text('0'), findsOneWidget);
    expect(_lamp('off'), findsOneWidget);
    expect(_lamp('on'), findsNothing);
  });

  testWidgets('пока прогресс грузится, серии в шапке нет', (tester) async {
    await tester.pumpWidget(app(streak: null));

    expect(find.text('Доброе утро!'), findsOneWidget);
    expect(_lamp('on'), findsNothing);
    expect(_lamp('off'), findsNothing);
  });

  testWidgets('тап по лампаде вызывает обработчик с вибрацией', (tester) async {
    final haptics = recordHaptics(tester);
    var taps = 0;
    await tester.pumpWidget(app(streak: 2, onStreakTap: () => taps++));

    await tester.tap(_lamp('on'));

    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('ink лампады заметен при наведении и удержании', (tester) async {
    await tester.pumpWidget(app(streak: 2));

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    final overlayColor = inkWell.overlayColor!;
    final hovered = overlayColor.resolve({WidgetState.hovered});
    final pressed = overlayColor.resolve({WidgetState.pressed});

    expect(hovered, isNotNull);
    expect(pressed, isNotNull);
    expect(pressed!.a, greaterThan(hovered!.a));
  });

  testWidgets('ink лампады рисуется поверх стеклянной подложки шапки', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FrostedHomeHeader(
            child: HomeHeader(
              now: DateTime(2026, 10, 22, 6, 16),
              streak: 2,
              onStreakTap: () {},
            ),
          ),
        ),
      ),
    );

    final materials = find.ancestor(
      of: find.byType(InkWell),
      matching: find.byType(Material),
    );
    expect(
      tester.widget<Material>(materials.first).type,
      MaterialType.transparency,
    );
  });

  testWidgets('семантическая активация лампадки вызывает обработчик один раз', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    final haptics = recordHaptics(tester);
    await tester.pumpWidget(app(streak: 2, onStreakTap: () => taps++));

    final node = tester.getSemantics(
      find.bySemanticsLabel('Лампадка: 2 дня подряд'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    // The test binding owns this widget tree's semantics owner.
    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await tester.pump();

    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    semantics.dispose();
  });

  testWidgets('кнопка серии не меньше 44 pt по высоте', (tester) async {
    await tester.pumpWidget(app(streak: 2));

    final button = find.bySemanticsLabel('Лампадка: 2 дня подряд');
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(button).width, greaterThanOrEqualTo(68));
  });

  testWidgets('шапка над списком размыта и мягко растворяется книзу', (
    tester,
  ) async {
    const key = ValueKey('header');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: FrostedHomeHeader(child: SizedBox(key: key, height: 60)),
          ),
        ),
      ),
    );

    // Ниже самой шапки зона растворения, а не чёткая граница.
    final frosted = tester.getRect(find.byType(FrostedHomeHeader));
    expect(frosted.height, greaterThan(60 + 12));
    // Размытие той же силы, что у стекла, плавно сходит на нет под
    // градиентной маской: без ступенек из полос разной силы.
    expectSmoothFade(tester, find.byType(FrostedHomeHeader));
  });

  testWidgets('крупный шрифт переносит приветствие, а не ломает шапку', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app(streak: 128));

    expect(tester.takeException(), isNull);
    expect(find.text('128'), findsOneWidget);
  });
}
