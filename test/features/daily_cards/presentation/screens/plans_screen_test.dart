import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/brand_loading_view.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/plans_screen.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_progress_header.dart';

void main() {
  const topic = DayCard(
    id: 'basics-topic-12',
    type: CardType.basics,
    body: 'Текст темы',
    title: 'Двенадцатая тема',
    source: 'Азбука веры',
  );

  Widget buildApp(Future<DayCard?> Function() load) => ProviderScope(
    overrides: [courseTopicProvider.overrideWith((ref) => load())],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: PlansScreen()),
    ),
  );

  testWidgets(
    'кнопка помощи открывает руководство по планам и возвращает к курсам',
    (tester) async {
      await tester.pumpWidget(buildApp(() async => topic));
      await tester.pumpAndSettle();
      final help = find.descendant(
        of: find.byType(SliverAppBar),
        matching: find.byTooltip('Помощь'),
      );
      expect(help, findsOneWidget);
      await tester.tap(help);
      await tester.pumpAndSettle();
      expect(find.text('Как проходить планы'), findsOneWidget);
      expect(find.text('Основы веры'), findsOneWidget);
      expect(find.textContaining('365 тем'), findsOneWidget);
      expect(find.textContaining('Свайп вверх'), findsOneWidget);
      expect(
        find.textContaining('не зависит от календарной даты'),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Двенадцатая тема'), findsOneWidget);
    },
  );

  testWidgets('показывает загрузку курса', (tester) async {
    final pending = Completer<DayCard?>();
    await tester.pumpWidget(buildApp(() => pending.future));
    expect(find.byType(BrandLoadingView), findsOneWidget);
    pending.complete(topic);
    await tester.pumpAndSettle();
    expect(find.byType(BrandLoadingView), findsNothing);
    expect(find.text('Тема 12 из 365'), findsOneWidget);
  });

  testWidgets('после ошибки повторно загружает личную тему', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      buildApp(() async {
        attempts++;
        return attempts == 1 ? null : topic;
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить «Основы веры»'), findsOneWidget);
    expect(find.byType(CourseProgressHeader), findsNothing);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Двенадцатая тема'), findsOneWidget);
    expect(find.text('Тема 12 из 365'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);
  });
}
