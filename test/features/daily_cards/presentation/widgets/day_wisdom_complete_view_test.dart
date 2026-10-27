import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_wisdom_complete_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('повторный итог виден уже в первом кадре', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await container.read(dayProgressProvider.future);
    expect(
      await container
          .read(dayProgressProvider.notifier)
          .completeWisdom(date: today),
      isTrue,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DayWisdomCompleteView(
              date: today,
              recordsCompletion: false,
              countsDay: true,
              onDone: () {},
            ),
          ),
        ),
      ),
    );

    final title = find.text('Слава Богу!');
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: title, matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 1);
  });
}
