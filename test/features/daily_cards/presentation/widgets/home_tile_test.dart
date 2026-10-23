import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_tile.dart';

void main() {
  Future<Rect> tileRect(WidgetTester tester, HomeTile tile) async {
    // Широкий экран: заголовок гарантированно в одну строку.
    tester.view
      ..physicalSize = const Size(900, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ListView(children: [tile])),
      ),
    );
    return tester.getRect(
      find.descendant(
        of: find.byType(HomeTile),
        matching: find.byType(InkWell),
      ),
    );
  }

  const trailing = SizedBox(key: ValueKey('checks'), width: 20, height: 14);

  HomeTile tile({String? subtitle, double? minHeight}) => HomeTile(
    title: 'Мудрость',
    type: CardType.quote,
    semanticsLabel: 'Мудрость',
    onTap: () {},
    titleTrailing: trailing,
    subtitle: subtitle,
    minHeight: minHeight ?? HomeTile.compactHeight,
  );

  testWidgets('компактная плитка: заголовок с отметкой в одну строку', (
    tester,
  ) async {
    final rect = await tileRect(tester, tile());

    expect(rect.height, HomeTile.compactHeight);
    final title = tester.getRect(find.text('Мудрость'));
    final checks = tester.getRect(find.byKey(const ValueKey('checks')));
    // Отметка прочтения справа от заголовка, а не отдельной строкой над ним.
    expect(checks.left, greaterThan(title.right));
    expect(checks.center.dy, closeTo(title.center.dy, 2));
    expect(title.center.dy, closeTo(rect.center.dy, 1));
  });

  testWidgets('подпись под заголовком умещается в компактную высоту', (
    tester,
  ) async {
    final rect = await tileRect(tester, tile(subtitle: '0/365'));

    expect(rect.height, HomeTile.compactHeight);
    // Цвета текста как у заголовка «Сегодня» и подписей главной.
    expect(
      tester.widget<Text>(find.text('Мудрость')).style?.color,
      AppColorsExtension.light.ink,
    );
    expect(
      tester.widget<Text>(find.text('0/365')).style?.color,
      AppColorsExtension.light.textSecondary,
    );
  });

  testWidgets('плитка держит заданную минимальную высоту', (tester) async {
    final rect = await tileRect(tester, tile(minHeight: 116));

    expect(rect.height, 116);
  });
}
