import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/reading_overflow_listener.dart';
import 'package:lampada/core/widgets/selectable_share_area.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/card_content.dart';

/// Кириллический наполнитель заданной длины — не привязывает шрифт/скролл-
/// пороги к реальному контенту с azbyka.ru.
String _filler(int length) {
  final buffer = StringBuffer();
  while (buffer.length < length) {
    buffer.write('слово ');
  }
  return buffer.toString().substring(0, length);
}

DayCard _card(String body, {CardType type = CardType.advice}) =>
    DayCard(id: 'test', type: type, body: body, source: 'Тестовый источник');

// Ширина/высота как у телефона — дефолтная тестовая поверхность (~800px)
// не даёт длинному тексту перенестись на строки, чтобы переполнить 300px.
Widget _buildApp(DayCard card) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SizedBox(width: 320, height: 300, child: CardContent(card: card)),
  ),
);

double? _fontSizeOf(WidgetTester tester, String body) =>
    tester.widget<Text>(find.text(body)).style?.fontSize;

void main() {
  testWidgets('превью сокращается по высоте при системном увеличении', (
    tester,
  ) async {
    final card = _card(_filler(3000));
    bool? needsFullText;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 160,
              height: 180,
              child: ReadingOverflowListener(
                onChanged: (value) => needsFullText = value,
                child: CardContent(
                  card: card,
                  showBadge: false,
                  showSource: false,
                  scrollable: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.fontSize, 20);
    expect(text.data, endsWith('…'));
    expect(text.data!.length, lessThan(150));
    expect(tester.getSize(find.byType(Text)).height, lessThanOrEqualTo(180));
    expect(needsFullText, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final type in CardType.values) {
    testWidgets('карточка $type вмещает весь текст длиннее 150 символов', (
      tester,
    ) async {
      final body = List.filled(10, 'Один два три да').join('\n');
      final card = _card('$body\nПоследняя строка', type: type);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: CardContent(
                card: card,
                showBadge: false,
                showSource: false,
                scrollable: false,
              ),
            ),
          ),
        ),
      );
      expect(find.text(card.body), findsOneWidget);
      expect(
        _fontSizeOf(tester, card.body),
        type == CardType.reading ? 24 : 22,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in {
    180.0: 27.0,
    165.0: 24.0,
    145.0: 22.0,
    130.0: 20.0,
  }.entries) {
    testWidgets(
      'карточка выбирает ступень ${entry.value} при высоте ${entry.key}',
      (tester) async {
        final card = _card('Один\nДва\nТри\nЧетыре');
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: entry.key,
                child: CardContent(
                  card: card,
                  showBadge: false,
                  showSource: false,
                  scrollable: false,
                ),
              ),
            ),
          ),
        );
        expect(_fontSizeOf(tester, card.body), entry.value);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('подпись источника оставляет место за счёт меньшей ступени', (
    tester,
  ) async {
    final card = _card('Один\nДва\nТри\nЧетыре');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: CardContent(card: card, showBadge: false, scrollable: false),
          ),
        ),
      ),
    );
    expect(_fontSizeOf(tester, card.body), 22);
    expect(
      tester.getRect(find.text('— Тестовый источник')).bottom,
      lessThanOrEqualTo(180),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('системное увеличение не компенсируется меньшей ступенью', (
    tester,
  ) async {
    final card = _card('Один\nДва\nТри\nЧетыре');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              height: 180,
              child: CardContent(
                card: card,
                showBadge: false,
                showSource: false,
              ),
            ),
          ),
        ),
      ),
    );
    expect(_fontSizeOf(tester, card.body), 27);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(card.body),
    );
    expect(paragraph.textScaler.scale(27), 54);
    expect(tester.takeException(), isNull);
  });

  testWidgets('короткая карточка: шрифт 27px, без намёка на скролл', (
    tester,
  ) async {
    final card = _card(_filler(20));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(_fontSizeOf(tester, card.body), 27);
    expect(find.byIcon(CupertinoIcons.chevron_down), findsNothing);
  });

  testWidgets('карточка 300 символов уменьшается до нижней ступени', (
    tester,
  ) async {
    final card = _card(_filler(300));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(_fontSizeOf(tester, card.body), 20);
  });

  testWidgets('длинная карточка: минимум 20, намёк на скролл виден', (
    tester,
  ) async {
    final card = _card(_filler(600));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(_fontSizeOf(tester, card.body), 20);
    expect(find.byIcon(CupertinoIcons.chevron_down), findsOneWidget);
  });

  testWidgets('после скролла длинной карточки до конца намёк исчезает', (
    tester,
  ) async {
    final card = _card(_filler(600));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();
    expect(find.byIcon(CupertinoIcons.chevron_down), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();

    expect(find.byIcon(CupertinoIcons.chevron_down), findsNothing);
  });

  testWidgets('в читалке карточка показывает первые 150 символов и троеточие', (
    tester,
  ) async {
    final card = _card(_filler(3000), type: CardType.basics);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: CardContent(card: card, showBadge: false, scrollable: false),
          ),
        ),
      ),
    );
    await tester.pump();

    final preview = '${card.body.substring(0, 150)}…';
    final text = tester.widget<Text>(find.text(preview));
    expect(text.style?.fontSize, 20);
    expect(find.text(card.body), findsNothing);
    expect(find.byTooltip('Открыть полный текст'), findsNothing);
  });

  testWidgets('в Основах сохраняются разделяющие абзацы двойные переносы', (
    tester,
  ) async {
    final card = _card(
      'Первый абзац\n\nВторой абзац\n\n\nТретий абзац',
      type: CardType.basics,
    );

    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(find.text(card.body), findsOneWidget);
  });

  testWidgets('вмещающийся текст Основ сохраняет исходные переносы', (
    tester,
  ) async {
    final preview = '${'а' * 149}\n';
    final card = _card('$preview\n', type: CardType.basics);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: CardContent(card: card, showBadge: false, scrollable: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(card.body), findsOneWidget);
  });

  testWidgets('под текстом всегда подпись источника', (tester) async {
    final card = _card(_filler(50));
    await tester.pumpWidget(_buildApp(card));
    await tester.pump();

    expect(find.text('— Тестовый источник'), findsOneWidget);
  });

  testWidgets('текст карточки можно выделить и отправить', (tester) async {
    await tester.pumpWidget(_buildApp(_card(_filler(50))));

    expect(find.byType(SelectableShareArea), findsOneWidget);
  });
}
