import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_memory_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/frosted_fade.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_grid_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/read_status_checks.dart';

import 'frosted_fade_expectations.dart';

const _story = 'https://azbyka.ru/days/pokrov';
const _icon =
    'https://azbyka.ru/days/storage/images/icons-of-holidays/14/a.jpg';
const _title = 'Покров Пресвятой Владычицы нашей Богородицы и Приснодевы Марии';

/// Плитка стоит в половину ширины, как в ряду главной.
Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 180, child: child),
    ),
  ),
);

Finder _iconImage() => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is NetworkImage &&
      (widget.image as NetworkImage).url == _icon,
);

Rect _tile(WidgetTester tester) => tester.getRect(find.byType(HomeGridTile));

void main() {
  testWidgets('на плитке подпись «Память дня», а не имя святого', (
    tester,
  ) async {
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

    // Пока икона грузится, имени на плитке нет.
    expect(find.text('Память дня'), findsOneWidget);
    expect(find.text(_title), findsNothing);
    // Имя святого слышит скринридер.
    expect(find.bySemanticsLabel('Память дня: $_title'), findsOneWidget);

    await tester.tap(find.byType(DayMemoryTile));
    expect(taps, 1);
  });

  testWidgets('если икона не загрузилась, на плитке имя святого', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DayMemoryTile(
          day: const TodayCards(cards: [], title: 'Пасха', storyUrl: _story),
          iconUrl: _icon,
          onTap: () {},
        ),
      ),
    );
    // В тестах сеть отвечает ошибкой, и картинка уходит в errorBuilder.
    await tester.pump();

    expect(find.text('Память дня'), findsOneWidget);
    expect(find.text('Пасха'), findsOneWidget);
    // Цвет текста плиток как у приветствия.
    for (final text in ['Память дня', 'Пасха']) {
      expect(
        tester.widget<Text>(find.text(text)).style?.color,
        AppColorsExtension.light.ink,
      );
    }
  });

  testWidgets('икона занимает всю плитку', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DayMemoryTile(
          day: const TodayCards(cards: [], title: _title, storyUrl: _story),
          iconUrl: _icon,
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    final tile = _tile(tester);
    final icon = tester.getRect(_iconImage());
    expect(icon, tile);
    expect(tile.height, greaterThanOrEqualTo(HomeGridTile.minHeight));
    expect(
      tester.widget<Image>(_iconImage()).fit,
      BoxFit.cover,
      reason: 'икона заполняет плитку без полей',
    );
  });

  testWidgets('подпись внизу на матовом стекле во всю ширину плитки', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DayMemoryTile(
          day: const TodayCards(cards: [], title: _title, storyUrl: _story),
          iconUrl: _icon,
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    final tile = _tile(tester);
    final label = tester.getRect(find.text('Память дня'));
    expect(tile.bottom - label.bottom, lessThan(tile.height / 4));

    final backdrop = find.ancestor(
      of: find.text('Память дня'),
      matching: find.byType(BackdropFilter),
    );
    expect(backdrop, findsOneWidget);
    expect(tester.widget<BackdropFilter>(backdrop).filter, isA<ImageFilter>());
    final bandFinder = find
        .ancestor(
          of: find.text('Память дня'),
          matching: find.byType(DecoratedBox),
        )
        .first;
    // Не таблетка, а перекрытие: от края до края и до самого низа.
    final band = tester.getRect(bandFinder);
    expect(band.left, tile.left);
    expect(band.right, tile.right);
    expect(band.bottom, tile.bottom);
    // Стекло полупрозрачное: икона под ним угадывается.
    final decoration =
        tester.widget<DecoratedBox>(bandFinder).decoration as BoxDecoration;
    expect(decoration.color!.a, inExclusiveRange(0.2, 0.7));
    expect(decoration.borderRadius, isNull);
    // Верхний край стекла не резкий: над полосой зона растворения, где
    // размытие той же силы плавно сходит на нет.
    expect(decoration.border, isNull);
    final fadeRect = tester.getRect(find.byType(FrostedFade));
    expect(fadeRect.bottom, band.top);
    expect(fadeRect.left, tile.left);
    expect(fadeRect.right, tile.right);
    expectSmoothFade(tester, find.byType(HomeGridTile));
  });

  testWidgets('без иконы на плитке имя святого', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DayMemoryTile(
          day: const TodayCards(cards: [], title: 'Пасха', storyUrl: _story),
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text('Память дня'), findsOneWidget);
    expect(find.text('Пасха'), findsOneWidget);
  });

  testWidgets('пост на плитке не отмечается', (tester) async {
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

    expect(find.text('Постный день'), findsNothing);
  });

  testWidgets('галочки справа от подписи, как у «Мудрости дня»', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const DayMemoryTile(
          day: TodayCards(cards: [], title: 'Пасха', storyUrl: _story),
        ),
      ),
    );

    final checks = find.byType(ReadStatusChecks);
    expect(checks, findsOneWidget);
    expect(tester.widget<ReadStatusChecks>(checks).isUnread, isTrue);
    expect(
      tester.getRect(checks).left,
      greaterThanOrEqualTo(tester.getRect(find.text('Память дня')).right),
    );
    final label = tester.widget<Text>(find.text('Память дня'));
    expect(label.maxLines, 1);
  });

  testWidgets('прочитанный рассказ отмечен галочками', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DayMemoryTile(
          day: TodayCards(cards: [], title: 'Пасха', storyUrl: _story),
          isRead: true,
        ),
      ),
    );

    expect(
      tester.widget<ReadStatusChecks>(find.byType(ReadStatusChecks)).isUnread,
      isFalse,
    );
    expect(
      find.bySemanticsLabel('Память дня: Пасха. Прочитано'),
      findsOneWidget,
    );
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

    final tile = tester.widget<HomeGridTile>(find.byType(HomeGridTile));
    expect(tile.onTap, isNull);
  });
}
