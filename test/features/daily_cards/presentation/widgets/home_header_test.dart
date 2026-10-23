import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_header.dart';

Finder _lamp(String state) =>
    find.image(AssetImage('assets/illustrations/lampada_$state.png'));

void main() {
  Widget app({
    required int? streak,
    VoidCallback? onStreakTap,
    ThemeData? theme,
    bool isFast = false,
  }) => MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Scaffold(
      body: HomeHeader(
        date: DateTime(2026, 10, 22, 6, 16),
        isFast: isFast,
        streak: streak,
        onStreakTap: onStreakTap ?? () {},
      ),
    ),
  );

  testWidgets('шапка начинается сразу с «Сегодня», без приветствия', (
    tester,
  ) async {
    await tester.pumpWidget(app(streak: 3));

    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('22 октября', findRichText: true), findsOneWidget);
    expect(find.textContaining('Добр'), findsNothing);
    expect(tester.widget<Text>(find.text('Сегодня')).style?.fontFamily, 'Lora');
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

  testWidgets('дата и пост одной строкой над «Сегодня»', (tester) async {
    await tester.pumpWidget(app(streak: 1, isFast: true));

    // Одна строка одного кегля, а не две разрозненные подписи сбоку от
    // крупного заголовка.
    final line = find.text('22 октября · Постный день', findRichText: true);
    expect(line, findsOneWidget);
    final today = tester.getRect(find.text('Сегодня'));
    final rect = tester.getRect(line);
    expect(rect.bottom, lessThanOrEqualTo(today.top));
    expect(rect.left, today.left);
    // Дата и пост одного цвета: строка читается одной подписью.
    final colors = <Color?>{};
    tester.widget<RichText>(line).text.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        colors.add(span.style?.color);
      }
      return true;
    });
    expect(
      tester.widget<RichText>(line).text.style?.color,
      AppColorsExtension.light.textSecondary,
    );
    expect(
      colors.nonNulls.where((c) => c != AppColorsExtension.light.textSecondary),
      isEmpty,
    );
  });

  testWidgets('лампада стоит по центру блока даты и заголовка', (tester) async {
    await tester.pumpWidget(app(streak: 2));

    final block = tester.getRect(find.byType(HomeHeader));
    final lamp = tester.getRect(
      find.bySemanticsLabel('Лампадка: 2 дня подряд'),
    );
    expect(lamp.center.dy, closeTo(block.center.dy, 4));
  });

  testWidgets('пока прогресс грузится, серии в шапке нет', (tester) async {
    await tester.pumpWidget(app(streak: null));

    expect(find.text('Сегодня'), findsOneWidget);
    expect(_lamp('on'), findsNothing);
    expect(_lamp('off'), findsNothing);
  });

  testWidgets('тап по лампаде вызывает обработчик', (tester) async {
    var taps = 0;
    await tester.pumpWidget(app(streak: 2, onStreakTap: () => taps++));

    await tester.tap(_lamp('on'));

    expect(taps, 1);
  });

  testWidgets('кнопка серии не меньше 44 pt по высоте', (tester) async {
    await tester.pumpWidget(app(streak: 2));

    final button = find.bySemanticsLabel('Лампадка: 2 дня подряд');
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
  });

  testWidgets('крупный шрифт переносит заголовок, а не ломает шапку', (
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
