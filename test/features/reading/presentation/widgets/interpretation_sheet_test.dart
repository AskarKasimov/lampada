import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/core/widgets/app_share_button.dart';
import 'package:lampada/core/widgets/selectable_share_area.dart';
import 'package:lampada/features/reading/domain/entities/daily_reading.dart';
import 'package:lampada/features/reading/presentation/widgets/interpretation_sheet.dart';

import '../../../../support/text_selection.dart';

void main() {
  testWidgets('текст толкования можно выделить', (tester) async {
    const verse = Verse(
      number: 1,
      chapter: 10,
      text: 'Стих',
      interpretation: 'Текст толкования',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: InterpretationSheet(verse: verse, author: 'Феофилакт'),
          ),
        ),
      ),
    );

    expect(find.byType(SelectableShareArea), findsOneWidget);
    expect(find.byType(AppShareButton), findsOneWidget);
    await expectTextCanBeCopied(
      tester,
      find.text(verse.interpretation!),
      contains: verse.interpretation!,
    );
    await expectTextCanBeCopied(
      tester,
      find.text('Феофилакт'),
      contains: verse.interpretation!,
    );
  });
}
