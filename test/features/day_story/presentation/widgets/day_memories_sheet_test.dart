import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_memory.dart';
import 'package:lampada/features/day_story/presentation/widgets/day_memories_sheet.dart';

const _foma = DayMemory(
  title: 'Прп. Фомы́, иже в Мале́и',
  storyUrl: 'https://azbyka.ru/days/sv-foma-malein',
);
const _akakij = DayMemory(
  title: 'Прп. Ака́кия Синайского',
  storyUrl: 'https://azbyka.ru/days/sv-akakij-sinajskij',
);
const _icon = DayMemory(
  title: 'Казанской иконы Божией Матери',
  storyUrl: 'https://azbyka.ru/days/ikona-kazanskaja',
);

void main() {
  late DayMemory? selected;

  Future<void> open(
    WidgetTester tester, {
    String currentUrl = 'https://azbyka.ru/days/sv-akakij-sinajskij',
    Set<String> readUrls = const {},
  }) async {
    selected = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => selected = await showDayMemoriesSheet(
                context,
                memories: const [_foma, _akakij, _icon],
                currentUrl: currentUrl,
                readUrls: readUrls,
              ),
              child: const Text('Список'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Список'));
    await tester.pumpAndSettle();
  }

  testWidgets('показывает всех поминаемых в этот день по порядку', (
    tester,
  ) async {
    await open(tester);

    final tops = [
      for (final memory in [_foma, _akakij, _icon])
        tester.getTopLeft(find.text(memory.title)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text('Прочитано 0 из 3'), findsOneWidget);
  });

  testWidgets('отмечает открытого святого и прочитанных', (tester) async {
    await open(tester, readUrls: {_foma.storyUrl});

    expect(find.bySemanticsLabel('${_akakij.title}. Сейчас'), findsOneWidget);
    expect(find.bySemanticsLabel('${_foma.title}. Прочитано'), findsOneWidget);
    expect(find.bySemanticsLabel(_icon.title), findsOneWidget);
    expect(find.text('Прочитано 1 из 3'), findsOneWidget);
  });

  testWidgets('выбор святого закрывает шторку и возвращает его', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text(_icon.title));
    await tester.pumpAndSettle();

    expect(find.byType(DayMemoriesSheet), findsNothing);
    expect(selected, _icon);
  });
}
