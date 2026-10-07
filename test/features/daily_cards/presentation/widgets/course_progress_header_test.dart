import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_progress_header.dart';

const _topic = DayCard(
  id: 'basics-topic-3',
  type: CardType.basics,
  body: 'Текст темы',
  title: 'Тема курса',
  source: 'Источник',
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('курс показывает только заголовок и полосу прогресса', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        CourseProgressHeader(
          topic: _topic,
          completedTopicCount: 73,
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Основы веры'), findsOneWidget);
    expect(find.text('Тема курса'), findsNothing);
    expect(find.textContaining('Прочитано'), findsNothing);
    // Счётчик тем стоит справа от полосы, на одной с ней линии.
    final counter = tester.getRect(find.text('73/365'));
    final barRect = tester.getRect(find.byType(LinearProgressIndicator));
    expect(counter.left, greaterThan(barRect.right));
    expect(counter.center.dy, closeTo(barRect.center.dy, 2));
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(73 / 365, 1e-9));
    expect(
      find.bySemanticsLabel(RegExp('Прочитано 73 из 365')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('крупный счётчик помещается на узком экране', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: CourseProgressHeader(
            topic: _topic,
            completedTopicCount: 365,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final counter = tester.getRect(find.text('365/365'));
    final bar = tester.getRect(find.byType(LinearProgressIndicator));
    expect(counter.right, lessThanOrEqualTo(304));
    expect(bar.width, greaterThan(0));
    expect(bar.right, lessThan(counter.left));
  });

  testWidgets('без счётчика прочитанного полосы прогресса нет', (tester) async {
    await tester.pumpWidget(
      _app(
        CourseProgressHeader(
          topic: _topic,
          completedTopicCount: null,
          onTap: () {},
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('/365'), findsNothing);
  });

  testWidgets('справка о курсе открывается кнопкой на плитке', (tester) async {
    var info = false;
    var opened = false;
    await tester.pumpWidget(
      _app(
        CourseProgressHeader(
          topic: _topic,
          completedTopicCount: 0,
          onTap: () => opened = true,
          onInfo: () => info = true,
        ),
      ),
    );
    await tester.tap(find.byTooltip('О курсе'));
    expect(info, isTrue);
    expect(opened, isFalse);
  });
}
