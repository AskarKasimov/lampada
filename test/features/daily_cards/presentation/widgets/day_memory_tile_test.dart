import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_memory_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_tile.dart';

const _story = 'https://azbyka.ru/days/pokrov';
const _icon =
    'https://azbyka.ru/days/storage/images/icons-of-holidays/14/a.jpg';
const _title = 'Покров Пресвятой Владычицы нашей Богородицы и Приснодевы Марии';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: ListView(children: [child])),
);

Finder _iconImage() => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is NetworkImage &&
      (widget.image as NetworkImage).url == _icon,
);

void main() {
  testWidgets('плитка как у «Мудрости дня»: название и икона справа', (
    tester,
  ) async {
    // Ширина iPhone: длинное название Покрова рядом с иконой не помещается.
    tester.view
      ..physicalSize = const Size(402 * 3, 874 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        DayMemoryTile(
          day: const TodayCards(cards: [], title: _title, storyUrl: _story),
          iconUrl: _icon,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeTile), findsOneWidget);
    // Название говорит само за себя, подписи «Память дня» нет.
    expect(find.textContaining('ПАМЯТЬ ДНЯ'), findsNothing);
    expect(find.text(_title), findsOneWidget);
    expect(_iconImage(), findsOneWidget);
    expect(
      tester.getTopLeft(_iconImage()).dx,
      greaterThan(tester.getTopRight(find.text(_title)).dx),
      reason: 'икона справа от названия',
    );
    // Как иллюстрации соседних плиток: крупно, у правого нижнего угла и
    // уходит за нижний край плитки.
    final tile = tester.getRect(
      find.descendant(
        of: find.byType(HomeTile),
        matching: find.byType(InkWell),
      ),
    );
    final icon = tester.getRect(_iconImage());
    expect(icon.width, greaterThanOrEqualTo(96));
    expect(icon.bottom, greaterThan(tile.bottom));
    expect(
      icon.right,
      greaterThan(tile.right),
      reason: 'длинному названию икона уступает место за правым краем',
    );
    // Без пометки поста над названием нет пустой строки статуса:
    // название стоит посередине плитки.
    final title = tester.getRect(find.text(_title));
    expect(
      (title.top - tile.top) - (tile.bottom - title.bottom),
      inInclusiveRange(-4, 4),
    );

    await tester.tap(find.byType(HomeTile));
    expect(taps, 1);
  });

  testWidgets('короткое название: икона целиком внутри плитки', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DayMemoryTile(
          day: const TodayCards(
            cards: [],
            title: 'Сщмч. Иерофея, епископа Афинского',
            storyUrl: _story,
          ),
          iconUrl: _icon,
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    final tile = tester.getRect(
      find.descendant(
        of: find.byType(HomeTile),
        matching: find.byType(InkWell),
      ),
    );
    final icon = tester.getRect(_iconImage());
    expect(icon.right, lessThanOrEqualTo(tile.right - 8));
    expect(
      icon.left - tester.getRect(find.textContaining('Иерофея')).right,
      greaterThanOrEqualTo(8),
      reason: 'название не заезжает на икону',
    );
  });

  testWidgets('в постный день это видно на плитке', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DayMemoryTile(
          day: TodayCards(
            cards: [],
            title: _title,
            storyUrl: _story,
            isFast: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Постный день'), findsOneWidget);
  });

  testWidgets('без иконы название занимает плитку целиком', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DayMemoryTile(
          day: const TodayCards(cards: [], title: _title, storyUrl: _story),
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('без ссылки на рассказ плитка не нажимается', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DayMemoryTile(
          day: TodayCards(cards: [], title: _title),
        ),
      ),
    );
    await tester.pump();

    expect(_iconImage(), findsNothing);
    final tile = tester.widget<HomeTile>(find.byType(HomeTile));
    expect(tile.onTap, isNull);
  });
}
