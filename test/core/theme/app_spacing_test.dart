import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_spacing.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/course_progress_header.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_entry_row.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/vertical_card_reader.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final inset in [16.0, 24.0]) {
      testWidgets(
        'поля $inset из темы $brightness используются списком, курсом и читалкой',
        (tester) async {
          final controller = PageController();
          addTearDown(controller.dispose);
          final theme = brightness == Brightness.light
              ? AppTheme.light
              : AppTheme.dark;

          await tester.pumpWidget(
            MaterialApp(
              theme: inset == 16
                  ? theme
                  : theme.copyWith(
                      extensions: [
                        ...theme.extensions.values.where(
                          (e) => e is! AppSpacing,
                        ),
                        AppSpacing(
                          screenInset: inset,
                          dayEntryInset: inset + 4,
                        ),
                      ],
                    ),
              home: Scaffold(
                body: Column(
                  children: [
                    DayEntryRow(
                      label: 'ЦИТАТА',
                      text: 'Короткая мысль',
                      isUnread: true,
                      onTap: () {},
                    ),
                    CourseProgressHeader(
                      completedTopicCount: 0,
                      topic: const DayCard(
                        id: 'basics-topic-1',
                        type: CardType.basics,
                        body: 'Текст темы',
                        title: 'Тема курса',
                        source: 'Источник',
                      ),
                      onTap: () {},
                    ),
                    Expanded(
                      child: VerticalCardReader(
                        controller: controller,
                        itemCount: 1,
                        onPageChanged: (_) {},
                        itemBuilder: (_, _) => const SizedBox.expand(),
                        header: const SizedBox.shrink(),
                        leftRail: const SizedBox.shrink(),
                        actions: const SizedBox.shrink(),
                        onClose: () {},
                        closeColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          final rowText = tester.getRect(find.text('Короткая мысль'));
          final reader = tester.getRect(find.byType(PageView));
          expect(rowText.left, inset + 4);
          expect(rowText.right, 800 - inset - 4);
          expect(tester.getTopLeft(find.text('Тема курса')).dx, inset);
          expect(reader.left, inset + 13);
          expect(reader.right, 800 - inset);
          final ink = find.descendant(
            of: find.byType(DayEntryRow),
            matching: find.byType(InkWell),
          );
          expect(tester.getRect(ink).left, 0);
          expect(tester.getRect(ink).right, 800);
        },
      );
    }
  }
}
