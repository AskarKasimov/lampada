import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/reminders/data/services/notification_service.dart';
import 'package:lampada/features/reminders/domain/entities/planned_reminder.dart';
import 'package:lampada/features/reminders/presentation/providers/providers.dart';
import 'package:lampada/features/shell/presentation/widgets/analytics_profile_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';

class _Notifications implements NotificationService {
  @override
  Future<void> init({void Function(NotificationTap tap)? onTap}) async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> isPermitted() async => false;
  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {}
  @override
  Future<void> cancelAll() async {}
}

class _Progress extends DayProgressNotifier {
  @override
  Future<DayProgress> build() async => DayProgress(
    readTypes: const {},
    visitedDays: {for (var d = 4; d <= 6; d++) '2026-08-0$d'},
    wisdomCompletedDays: const {'2026-08-05', '2026-08-06'},
  );
}

void main() {
  testWidgets('атрибуты профиля собираются из состояния приложения', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'flutter.reminders_enabled': true,
      'flutter.theme_mode': 'dark',
    });
    final prefs = await SharedPreferences.getInstance();
    final analytics = FakeAnalytics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWithValue(analytics),
          notificationServiceProvider.overrideWithValue(_Notifications()),
          dayProgressProvider.overrideWith(_Progress.new),
          completedCourseTopicsProvider.overrideWith((ref) async => {1, 2, 3}),
        ],
        child: AnalyticsProfileSync(
          clock: () => DateTime(2026, 8, 6, 12),
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final profile = analytics.profiles.last;
    expect(profile.notificationsEnabled, isTrue);
    expect(profile.notificationsPermitted, isFalse);
    expect(profile.streak, 3);
    expect(profile.wisdomDaysTotal, 2);
    expect(profile.courseTopicsCompleted, 3);
    expect(profile.bookmarksCount, 0);
    expect(profile.theme, 'dark');
  });

  testWidgets('одинаковый профиль повторно не отправляется', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final analytics = FakeAnalytics();
    Widget app() => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        analyticsProvider.overrideWithValue(analytics),
        notificationServiceProvider.overrideWithValue(_Notifications()),
      ],
      child: AnalyticsProfileSync(
        clock: () => DateTime(2026, 8, 6, 12),
        child: const SizedBox(),
      ),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final sent = analytics.profiles.length;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(analytics.profiles.length, sent);
    expect(analytics.profiles.toSet().length, analytics.profiles.length);
  });
}
