import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_wisdom_tile.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/orthodox_cross.dart';

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

  testWidgets('во время загрузки плитка дня не открывается', (tester) async {
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
