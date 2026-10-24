import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_progress_header.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/frosted_fade.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_grid_tile.dart';

import '../../../../support/haptics.dart';

const _topic = DayCard(
  id: 'basics-topic-3',
  type: CardType.basics,
  body: 'Текст темы',
  title: 'Тема курса',
  source: 'Источник',
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: ListView(children: [child])),
);

Finder _cover() => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == CourseProgressHeader.coverAsset,
);

void main() {
  testWidgets('плитка курса собрана как плитки дня, только широкая', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        CourseProgressHeader(
          topic: _topic,
          completedTopicCount: 73,
          onTap: () {},
        ),
      ),
    );

    final tile = tester.getRect(find.byType(HomeGridTile));
    // Горизонтальная, во всю ширину с общими полями.
    expect(tile.left, 16);
    expect(tile.right, 800 - 16);
    expect(tile.width, greaterThan(tile.height * 2));
    // Картина на всю плитку, как икона и «Картина дня» у плиток дня.
    expect(tester.getRect(_cover()), tile);
    expect(tester.widget<Image>(_cover()).fit, BoxFit.cover);
    // Снизу то же матовое стекло с мягким краем.
    expect(
      find.descendant(
        of: find.byType(HomeGridTile),
        matching: find.byType(FrostedFade),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(CupertinoIcons.book), findsNothing);
  });

  testWidgets('в стекле название, справа счётчик тем и галочки', (
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

    final tile = tester.getRect(find.byType(HomeGridTile));
    final title = tester.getRect(find.text('Основы веры'));
    final counter = tester.getRect(find.text('73/365'));
    final checks = tester.getRect(
      find.byIcon(CupertinoIcons.checkmark_alt).first,
    );
    expect(tile.bottom - title.bottom, lessThan(tile.height / 3));
    expect(counter.left, greaterThan(title.right));
    expect(counter.center.dy, closeTo(title.center.dy, 4));
    expect(checks.left, greaterThan(counter.right));
    // Счётчик на стекле поверх картины должен хорошо читаться: тёмный, как
    // название, и не мельче обычной подписи.
    final counterStyle = tester.widget<Text>(find.text('73/365')).style!;
    expect(counterStyle.color, AppColorsExtension.light.ink);
    expect(counterStyle.fontSize, greaterThanOrEqualTo(16));
    expect(find.text('Тема курса'), findsNothing);
    expect(find.byTooltip('О курсе'), findsNothing);
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
          body: ListView(
            children: [
              CourseProgressHeader(
                topic: _topic,
                completedTopicCount: 365,
                onTap: () {},
              ),
            ],
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

  testWidgets('тап по плитке открывает курс с лёгкой вибрацией', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
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
    await tester.tap(find.byType(CourseProgressHeader));
    expect(opened, isTrue);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });
}
