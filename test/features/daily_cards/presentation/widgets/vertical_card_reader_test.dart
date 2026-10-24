import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_content.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/vertical_card_reader.dart';

void main() {
  for (final fullscreenDialog in [false, true]) {
    testWidgets(
      'выход занимает ${fullscreenDialog ? 'правый крестик' : 'левую стрелку'} на реальном маршруте',
      (tester) async {
        final controller = PageController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      fullscreenDialog: fullscreenDialog,
                      builder: (_) => Scaffold(
                        body: VerticalCardReader(
                          controller: controller,
                          itemCount: 1,
                          onPageChanged: (_) {},
                          itemBuilder: (_, _) => const Text('Страница'),
                          header: const Text('Метка'),
                          leftRail: const SizedBox.shrink(),
                          actions: const SizedBox.shrink(),
                          onClose: () {},
                          closeColor: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Открыть'));
        await tester.pumpAndSettle();

        final expectedIcon = fullscreenDialog
            ? CupertinoIcons.xmark
            : CupertinoIcons.arrow_left;
        final button = find.byIcon(expectedIcon);
        expect(button, findsOneWidget);
        expect(
          find.byIcon(CupertinoIcons.xmark),
          fullscreenDialog ? findsOneWidget : findsNothing,
        );
        expect(
          find.byIcon(CupertinoIcons.arrow_left),
          fullscreenDialog ? findsNothing : findsOneWidget,
        );
        final buttonRect = tester.getRect(
          find.ancestor(of: button, matching: find.byType(IconButton)),
        );
        final rect = buttonRect;
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(
          rect.center.dx > tester.getSize(find.byType(Scaffold).last).width / 2,
          fullscreenDialog,
        );
        expect(
          find.byTooltip(fullscreenDialog ? 'Закрыть' : 'Назад'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('действие справа не перекрывает крестик модального ридера', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => Scaffold(
                    body: VerticalCardReader(
                      controller: controller,
                      itemCount: 1,
                      onPageChanged: (_) {},
                      itemBuilder: (_, _) => const Text('Страница'),
                      header: const Text('Метка'),
                      leftRail: const SizedBox.shrink(),
                      actions: const SizedBox.shrink(),
                      onClose: () {},
                      closeColor: Colors.black,
                      topRightAction: IconButton(
                        tooltip: 'Помощь',
                        onPressed: () {},
                        icon: const Icon(CupertinoIcons.info),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final closeRect = tester.getRect(find.byTooltip('Закрыть'));
    final actionRect = tester.getRect(find.byTooltip('Помощь'));
    expect(actionRect.top, greaterThanOrEqualTo(closeRect.bottom));
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
  });

  testWidgets('полная карточка использует место отсутствующей третьей кнопки', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PageController();
    addTearDown(controller.dispose);
    final body = List.filled(16, 'Строка текста').join('\n');
    const actionsKey = ValueKey('two-actions');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: VerticalCardReader(
            controller: controller,
            itemCount: 1,
            onPageChanged: (_) {},
            itemBuilder: (_, _) => CardContent(
              card: DayCard(
                id: 'full',
                type: CardType.quote,
                body: body,
                source: 'Источник',
              ),
              showBadge: false,
              scrollable: false,
            ),
            header: const Text('Цитата дня'),
            leftRail: const SizedBox.shrink(),
            actions: const SizedBox(key: actionsKey, width: 56, height: 116),
            onClose: () {},
            closeColor: Colors.black,
          ),
        ),
      ),
    );
    expect(find.text(body), findsOneWidget);
    expect(tester.widget<Text>(find.text(body)).style?.fontSize, 22);
    expect(
      tester.getRect(find.text('— Источник')).bottom,
      closeTo(tester.getRect(find.byKey(actionsKey)).top - 16, 1),
    );
    expect(tester.takeException(), isNull);
  });

  for (final body in [
    'Короткая карточка',
    List.filled(300, 'Длинная притча').join(' '),
  ]) {
    testWidgets(
      'короткий текст или превью остаётся по центру: ${body.length}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = PageController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: VerticalCardReader(
                controller: controller,
                itemCount: 1,
                onPageChanged: (_) {},
                itemBuilder: (_, _) => CardContent(
                  card: DayCard(
                    id: 'center',
                    type: CardType.parable,
                    body: body,
                    source: 'Источник',
                  ),
                  showBadge: false,
                  scrollable: false,
                ),
                header: const Text('Притча дня'),
                leftRail: const SizedBox.shrink(),
                actions: const SizedBox(width: 56, height: 176),
                onClose: () {},
                closeColor: Colors.black,
              ),
            ),
          ),
        );
        final contentTexts = find.descendant(
          of: find.byType(CardContent),
          matching: find.byType(Text),
        );
        final first = tester.getRect(contentTexts.first);
        final last = tester.getRect(contentTexts.last);
        final viewport = tester.getRect(find.byType(PageView));
        expect((first.top + last.bottom) / 2, closeTo(viewport.center.dy, 1));
        expect(last.bottom, lessThan(640));
      },
    );
  }

  testWidgets('свайп из нижней свободной области переключает карточку', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PageController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: VerticalCardReader(
            controller: controller,
            itemCount: 2,
            onPageChanged: (_) {},
            itemBuilder: (_, index) => CardContent(
              card: DayCard(
                id: '$index',
                type: CardType.advice,
                body: 'Карточка $index',
                source: 'Источник',
              ),
              showBadge: false,
              scrollable: false,
            ),
            header: const Text('Совет'),
            leftRail: const SizedBox.shrink(),
            actions: const SizedBox(width: 56, height: 176),
            onClose: () {},
            closeColor: Colors.black,
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(80, 750), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(controller.page, 1);
  });

  testWidgets('полный текст карточки не пересекает нижнюю панель действий', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = PageController();
    addTearDown(controller.dispose);
    final body = List.filled(16, 'Строка текста').join('\n');
    final card = DayCard(
      id: 'test',
      type: CardType.advice,
      body: body,
      source: 'Источник',
    );
    const actionsKey = ValueKey('actions');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: VerticalCardReader(
            controller: controller,
            itemCount: 1,
            onPageChanged: (_) {},
            itemBuilder: (_, _) =>
                CardContent(card: card, showBadge: false, scrollable: false),
            header: const Text('Совет дня'),
            leftRail: const SizedBox.shrink(),
            actions: const SizedBox(key: actionsKey, width: 56, height: 116),
            onClose: () {},
            closeColor: Colors.black,
          ),
        ),
      ),
    );
    expect(find.text(body), findsOneWidget);
    expect(
      tester.getRect(find.text(body)).bottom,
      lessThan(tester.getRect(find.byKey(actionsKey)).top),
    );
    expect(
      tester.getRect(find.text('— Источник')).bottom,
      lessThan(tester.getRect(find.byKey(actionsKey)).top),
    );
    expect(tester.takeException(), isNull);
  });
}
