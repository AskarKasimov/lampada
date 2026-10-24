import 'dart:ui' show SemanticsAction;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_wisdom_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_grid_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/orthodox_cross.dart';

import '../../../../support/haptics.dart';

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: child,
    ),
  ),
);

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('плитка дня без подзаголовка открывается при масштабе $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var opened = false;
      await tester.pumpWidget(
        _app(
          DayWisdomTile(isUnread: true, onTap: () => opened = true),
          scale: scale,
        ),
      );
      expect(find.text('Мудрость дня'), findsOneWidget);
      expect(find.text('Цитата, совет, притча и Евангелие'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Мудрость дня'));
      expect(opened, isTrue);
    });
  }

  testWidgets('заголовок внизу, галочки справа от него', (tester) async {
    // Половина ширины телефона: название не помещается в строку целиком,
    // но галочки всё равно стоят справа, а не переносятся под него.
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 180,
            child: DayWisdomTile(isUnread: true, onTap: () {}),
          ),
        ),
      ),
    );

    final tile = tester.getRect(find.byType(HomeGridTile));
    final title = tester.getRect(find.text('Мудрость дня'));
    expect(tile.bottom - title.bottom, lessThan(tile.height / 4));
    expect(
      tester.widget<Text>(find.text('Мудрость дня')).style?.fontSize,
      AppTheme.cardTitleSize,
    );
    // Цвет текста плиток как у приветствия, а не цвет плитки.
    expect(
      tester.widget<Text>(find.text('Мудрость дня')).style?.color,
      AppColorsExtension.light.ink,
    );
    final checks = tester.getRect(
      find.byIcon(CupertinoIcons.checkmark_alt).first,
    );
    // Название в одну строку, даже когда половины ширины ему мало.
    final titleText = tester.widget<Text>(find.text('Мудрость дня'));
    expect(titleText.maxLines, 1);
    expect(titleText.softWrap, isFalse);
    expect(title.right, lessThanOrEqualTo(checks.left));
    expect(checks.left, greaterThanOrEqualTo(title.right));
    expect(checks.top, lessThan(title.bottom));
    expect(checks.right, greaterThanOrEqualTo(tile.right - 24));
  });

  testWidgets('крест крупный и занимает плитку над заголовком', (tester) async {
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 180,
            child: DayWisdomTile(isUnread: true, onTap: () {}),
          ),
        ),
      ),
    );

    final tile = tester.getRect(find.byType(HomeGridTile));
    final cross = tester.getRect(find.byType(OrthodoxCross));
    expect(cross.height, greaterThan(tile.height * 0.8));
    // Верх креста (8% холста) внутри плитки, а не за краем.
    expect(cross.top + cross.height * 0.08, greaterThan(tile.top));
  });

  testWidgets('картина дня занимает всю плитку вместо креста', (tester) async {
    const picture =
        'https://azbyka.ru/days/cache/600x480/storage/images/pictures-of-day/a.jpg';
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 180,
            child: DayWisdomTile(
              isUnread: true,
              pictureUrl: picture,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final image = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is NetworkImage &&
          (widget.image as NetworkImage).url == picture,
    );
    expect(image, findsOneWidget);
    expect(tester.getRect(image), tester.getRect(find.byType(HomeGridTile)));
    expect(tester.widget<Image>(image).fit, BoxFit.cover);
    // Пока картина грузится, крест не мелькает: видна заливка плитки.
    expect(find.byType(OrthodoxCross), findsNothing);
  });

  testWidgets('если картина не загрузилась, на плитке крест', (tester) async {
    await tester.pumpWidget(
      _app(
        DayWisdomTile(
          isUnread: true,
          pictureUrl: 'https://azbyka.ru/days/x.jpg',
          onTap: () {},
        ),
      ),
    );
    // В тестах сеть отвечает ошибкой, и картинка уходит в errorBuilder.
    await tester.pump();

    expect(find.byType(OrthodoxCross), findsOneWidget);
  });

  testWidgets('тап по плитке даёт лёгкую вибрацию', (tester) async {
    final haptics = recordHaptics(tester);
    var opened = false;
    await tester.pumpWidget(
      _app(DayWisdomTile(isUnread: true, onTap: () => opened = true)),
    );

    await tester.tap(find.byType(DayWisdomTile));

    expect(opened, isTrue);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('семантическая активация открывает плитку один раз', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final haptics = recordHaptics(tester);
    var taps = 0;
    await tester.pumpWidget(
      _app(DayWisdomTile(isUnread: true, onTap: () => taps++)),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Мудрость дня'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    // The test binding owns this widget tree's semantics owner.
    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await tester.pump();

    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    semantics.dispose();
  });

  testWidgets('под плиткой лёгкая тень', (tester) async {
    await tester.pumpWidget(_app(DayWisdomTile(isUnread: true, onTap: () {})));

    final shadows = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(DayWisdomTile),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .expand((decoration) => decoration.boxShadow ?? const <BoxShadow>[]);
    expect(shadows, isNotEmpty);
    expect(shadows.first.blurRadius, greaterThan(0));
  });

  testWidgets('во время загрузки плитка дня не открывается', (tester) async {
    final haptics = recordHaptics(tester);
    var opened = false;
    await tester.pumpWidget(
      _app(
        DayWisdomTile(
          isUnread: true,
          isLoading: true,
          onTap: () => opened = true,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Мудрость дня'));
    expect(opened, isFalse);
    expect(haptics, isEmpty, reason: 'выключенная плитка не вибрирует');
  });

  testWidgets('иллюстрация плитки дня это православный крест', (tester) async {
    await tester.pumpWidget(_app(DayWisdomTile(isUnread: true, onTap: () {})));
    expect(find.byType(OrthodoxCross), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.sunrise), findsNothing);
  });

  test('нижняя перекладина креста поднята левым от зрителя концом', () {
    final bar = OrthodoxCross.footrest(const Size.square(150));
    expect(bar.$1.dx, lessThan(bar.$2.dx));
    expect(bar.$1.dy, lessThan(bar.$2.dy));
  });
}
