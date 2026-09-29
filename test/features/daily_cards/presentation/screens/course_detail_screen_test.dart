import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/screens/course_detail_screen.dart';

void main() {
  Widget buildApp(int number, Set<int> completed) => ProviderScope(
    overrides: [
      courseTopicProvider.overrideWith(
        (ref) async => DayCard(
          id: 'basics-topic-$number',
          type: CardType.basics,
          title: 'Тема $number',
          body: 'Текст',
          source: 'Азбука веры',
        ),
      ),
      completedCourseTopicsProvider.overrideWith((ref) async => completed),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const CourseDetailScreen()),
  );

  testWidgets('показывает описание и источник курса', (tester) async {
    await tester.pumpWidget(buildApp(1, {}));
    await tester.pumpAndSettle();
    expect(find.text('О курсе'), findsOneWidget);
    expect(find.textContaining('365 тем об основах'), findsOneWidget);
    expect(find.text('Источник: «Азбука веры»'), findsOneWidget);
    expect(find.text('Прочитано 0 из 365'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining('карточка «Тема прочитана»'), findsOneWidget);
  });

  testWidgets('возвращение показывает следующую тему и отдельный прогресс', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(12, {1, 3}));
    await tester.pumpAndSettle();
    expect(find.text('Текущее чтение: Тема 12'), findsOneWidget);
    expect(find.text('Прочитано 2 из 365'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(2 / 365, 0.000001),
    );
  });

  testWidgets('старое место чтения без отметок показывает прогресс', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(209, {}));
    await tester.pumpAndSettle();
    expect(find.text('Прочитано 0 из 365'), findsOneWidget);
    expect(find.text('Текущее чтение: Тема 209'), findsOneWidget);
  });

  testWidgets('завершённый курс показывает итог', (tester) async {
    await tester.pumpWidget(
      buildApp(365, Set<int>.from(List.generate(365, (i) => i + 1))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Курс пройден'), findsOneWidget);
    expect(find.text('Для повторного чтения: Тема 365'), findsOneWidget);
  });

  testWidgets('ошибка прогресса предлагает повторную загрузку', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseTopicProvider.overrideWith(
            (ref) async => const DayCard(
              id: 'basics-topic-1',
              type: CardType.basics,
              body: 'Текст',
              source: 'Азбука веры',
            ),
          ),
          completedCourseTopicsProvider.overrideWith((ref) async {
            if (attempts++ == 0) throw StateError('Ошибка чтения');
            return <int>{};
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CourseDetailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Повторить загрузку прогресса'), findsOneWidget);
    await tester.tap(find.text('Повторить загрузку прогресса'));
    await tester.pumpAndSettle();
    expect(find.text('Прочитано 0 из 365'), findsOneWidget);
  });
}
