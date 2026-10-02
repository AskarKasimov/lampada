import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/selectable_share_area.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/presentation/widgets/verse_view.dart';

const _verse = Verse(number: 1, chapter: 10, text: 'Истинно говорю вам');

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('ступени учитывают номер стиха и кнопку толкования', (
    tester,
  ) async {
    const verse = Verse(number: 1, chapter: 10, text: 'Один\nДва\nТри\nЧетыре');
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 320,
          height: 250,
          child: VerseView(verse: verse, onOpenInterpretation: () {}),
        ),
      ),
    );
    expect(tester.widget<Text>(find.text(verse.text)).style?.fontSize, 24);
    expect(tester.getSize(find.byType(SingleChildScrollView)).height, 250);
    expect(tester.takeException(), isNull);
  });

  testWidgets('у стиха с толкованием есть кнопка перехода', (tester) async {
    await tester.pumpWidget(
      _app(VerseView(verse: _verse, onOpenInterpretation: () {})),
    );

    expect(find.byType(VerseInterpretationButton), findsOneWidget);
    expect(find.text('Толкование'), findsOneWidget);
    // Иконка нужна: текстовой ссылкой 12-м кеглем действие терялось под
    // номером стиха, и его не находили.
    expect(find.byIcon(CupertinoIcons.book), findsOneWidget);
  });

  testWidgets('без толкования кнопки нет — обещать пустоту нельзя', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const VerseView(verse: _verse)));

    expect(find.byType(VerseInterpretationButton), findsNothing);
  });

  testWidgets('короткий стих расположен по центру области чтения', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            height: 500,
            child: VerseView(verse: _verse),
          ),
        ),
      ),
    );

    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final verse = tester.getRect(find.text(_verse.text));

    expect(verse.center.dy, greaterThan(viewport.top + viewport.height * 0.35));
    expect(verse.center.dy, lessThan(viewport.top + viewport.height * 0.65));
  });

  testWidgets('длинный стих сохраняет кегль карточки Евангелия', (
    tester,
  ) async {
    final longVerse = Verse(
      number: 1,
      chapter: 10,
      text: List.filled(100, 'Длинный стих').join(' '),
    );
    await tester.pumpWidget(_app(VerseView(verse: longVerse)));

    final text = tester.widget<Text>(
      find.text('${longVerse.text.substring(0, 150)}…'),
    );

    expect(text.style?.fontSize, 20);
  });

  testWidgets('вмещающийся стих длиннее 150 символов показывается полностью', (
    tester,
  ) async {
    final longText = List.filled(30, 'Длинный стих').join(' ');
    final verse = Verse(number: 1, chapter: 10, text: longText);

    await tester.pumpWidget(_app(VerseView(verse: verse)));

    expect(find.text(longText), findsOneWidget);
  });

  testWidgets('кнопка зовёт колбэк', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      _app(VerseView(verse: _verse, onOpenInterpretation: () => opened = true)),
    );

    await tester.tap(find.byType(VerseInterpretationButton));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('hasInterpretation игнорирует пробельный текст', (tester) async {
    // Пустая строка из источника не должна порождать кнопку в пустоту.
    const blank = Verse(
      number: 1,
      chapter: 10,
      text: 'Стих',
      interpretation: '   ',
    );

    expect(blank.hasInterpretation, isFalse);
  });

  testWidgets('текст стиха можно выделить и отправить', (tester) async {
    await tester.pumpWidget(_app(const VerseView(verse: _verse)));

    expect(find.byType(SelectableShareArea), findsOneWidget);
  });
}
