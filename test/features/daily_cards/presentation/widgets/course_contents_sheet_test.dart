import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_contents_sheet.dart';

final _titles = [for (var i = 1; i <= 365; i++) 'Название темы $i'];

void main() {
  Future<int?> open(
    WidgetTester tester, {
    int currentTopic = 200,
    Set<int> completed = const {},
  }) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => selected = await showCourseContentsSheet(
                context,
                titles: _titles,
                currentTopic: currentTopic,
                completed: completed,
              ),
              child: const Text('Оглавление'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Оглавление'));
    await tester.pumpAndSettle();
    return selected;
  }

  testWidgets('открывается на текущей теме, а не с начала курса', (
    tester,
  ) async {
    await open(tester, currentTopic: 200);

    expect(find.text('Название темы 200').hitTestable(), findsOneWidget);
    expect(find.text('Название темы 1'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'^Тема 200\. Название темы 200\. Сейчас')),
      findsOneWidget,
    );
  });

  testWidgets('последняя тема открывается без пустоты под списком', (
    tester,
  ) async {
    await open(tester, currentTopic: 365);

    expect(find.text('Название темы 365').hitTestable(), findsOneWidget);
  });

  testWidgets('пройденные темы отмечены и посчитаны', (tester) async {
    await open(tester, currentTopic: 3, completed: {1, 2});

    expect(find.text('Пройдено 2 из 365'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Тема 1. Название темы 1. Пройдена'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Тема 4. Название темы 4'), findsOneWidget);
  });

  testWidgets('тап по теме закрывает оглавление и возвращает её номер', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => selected = await showCourseContentsSheet(
                context,
                titles: _titles,
                currentTopic: 3,
                completed: const {},
              ),
              child: const Text('Оглавление'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Оглавление'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Название темы 5'));
    await tester.pumpAndSettle();

    expect(selected, 5);
    expect(find.text('Название темы 5'), findsNothing);
  });
}
