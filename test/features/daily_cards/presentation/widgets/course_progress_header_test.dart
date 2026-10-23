import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
  testWidgets('счётчик тем стоит под заголовком, полосы нет', (tester) async {
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
    expect(find.byType(LinearProgressIndicator), findsNothing);
    // Справка о курсе открывается из читалки, на плитке кнопки нет.
    expect(find.byTooltip('О курсе'), findsNothing);
    final title = tester.getRect(find.text('Основы веры'));
    final counter = tester.getRect(find.text('73/365'));
    expect(counter.top, greaterThanOrEqualTo(title.bottom));
    expect(counter.left, title.left);
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
    expect(tester.getRect(find.text('365/365')).right, lessThanOrEqualTo(304));
  });

  testWidgets('без счётчика прочитанного у заголовка нет числа', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        CourseProgressHeader(
          topic: _topic,
          completedTopicCount: null,
          onTap: () {},
        ),
      ),
    );
    expect(find.textContaining('/365'), findsNothing);
  });

  testWidgets('тап по плитке открывает курс', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      _app(
        CourseProgressHeader(
          topic: _topic,
          completedTopicCount: 0,
          onTap: () => opened = true,
        ),
      ),
    );
    await tester.tap(find.text('0/365'));
    expect(opened, isTrue);
  });

  testWidgets('книга крупная и не теряется в низкой плитке', (tester) async {
    await tester.pumpWidget(
      _app(
        ListView(
          children: [
            CourseProgressHeader(
              topic: _topic,
              completedTopicCount: 0,
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    final tile = tester.getRect(
      find.descendant(
        of: find.byType(CourseProgressHeader),
        matching: find.byType(InkWell),
      ),
    );
    final book = tester.getRect(find.byIcon(CupertinoIcons.book));
    expect(book.height, greaterThan(tile.height * 1.25));
    expect(book.top, greaterThanOrEqualTo(tile.top - book.height * 0.1));
  });
}
