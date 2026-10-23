import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_event.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/reminders/data/services/notification_service.dart';
import 'package:lampada/features/reminders/domain/entities/planned_reminder.dart';
import 'package:lampada/features/reminders/presentation/providers/providers.dart';
import 'package:lampada/features/reminders/presentation/screens/reminder_permission_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';

class _Notifications implements NotificationService {
  _Notifications({this.grant = true});

  final bool grant;

  @override
  Future<void> init({void Function(NotificationTap tap)? onTap}) async {}

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<bool> isPermitted() async => grant;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  late FakeAnalytics analytics;

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool grant = true,
    ReminderPromptTrigger trigger = ReminderPromptTrigger.wisdom,
  }) async {
    analytics = FakeAnalytics();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWithValue(analytics),
          notificationServiceProvider.overrideWithValue(
            _Notifications(grant: grant),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReminderPermissionScreen(trigger: trigger),
                ),
              ),
              child: const Text('открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();
  }

  testWidgets('показ экрана уходит в аналитику с источником', (tester) async {
    await pumpScreen(tester, trigger: ReminderPromptTrigger.course);

    expect(analytics.single('reminder_prompt_shown'), {'trigger': 'course'});
  });

  testWidgets('согласие пишет ответ системы', (tester) async {
    await pumpScreen(tester, grant: false);

    await tester.tap(find.text('Напоминать'));
    await tester.pumpAndSettle();

    expect(analytics.single('reminder_prompt_answered'), {
      'choice': 'allow',
      'os_granted': false,
    });
  });

  testWidgets('«Не сейчас» пишет отказ', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Не сейчас'));
    await tester.pumpAndSettle();

    expect(analytics.single('reminder_prompt_answered'), {'choice': 'later'});
  });

  testWidgets('системный «назад» без ответа пишется как закрытие', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(analytics.single('reminder_prompt_answered'), {
      'choice': 'dismissed',
    });
  });

  testWidgets('называет пользу напоминаний цифрой', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('на 36% чаще'), findsOneWidget);
  });

  testWidgets('зовёт из соцсетей к ежедневному чтению', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Перестаньте сидеть в соцсетях'), findsOne);
    expect(find.textContaining('жития святых'), findsOneWidget);
  });

  testWidgets('не обещает «одно в день»', (tester) async {
    // Когда день не открыт, вечером приходит второе напоминание.
    await pumpScreen(tester);

    expect(find.textContaining('Одно в день'), findsNothing);
  });

  testWidgets('кнопки согласия и отказа на месте', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Напоминать'), findsOneWidget);
    expect(find.text('Не сейчас'), findsOneWidget);
  });
}
