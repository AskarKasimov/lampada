import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics_provider.dart';
import 'package:lampada/core/storage/shared_preferences_provider.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_progress.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';
import 'package:lampada/features/daily_cards/presentation/providers/providers.dart';
import 'package:lampada/features/reminders/data/services/notification_service.dart';
import 'package:lampada/features/reminders/domain/entities/planned_reminder.dart';
import 'package:lampada/features/reminders/presentation/providers/providers.dart';
import 'package:lampada/features/reminders/presentation/widgets/reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_analytics.dart';

class _Notifications implements NotificationService {
  @override
  Future<void> init({void Function(NotificationTap tap)? onTap}) async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> isPermitted() async => true;
  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {}
  @override
  Future<void> cancelAll() async {}
}

class _Progress extends DayProgressNotifier {
  _Progress(this.progress);

  final DayProgress progress;

  @override
  Future<DayProgress> build() async => progress;
}

void main() {
  final now = DateTime(2026, 8, 6, 10);

  Future<FakeAnalytics> pumpScheduler(
    WidgetTester tester,
    SharedPreferences prefs,
  ) async {
    final analytics = FakeAnalytics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWithValue(analytics),
          notificationServiceProvider.overrideWithValue(_Notifications()),
          todayCardsProvider.overrideWith(
            (ref) async => TodayCards(
              title: 'Святитель Николай',
              storyUrl: 'https://azbyka.ru/days/sv-nikolaj',
              cards: const [
                DayCard(
                  id: 'quote',
                  type: CardType.quote,
                  body: 'М',
                  source: 'И',
                ),
              ],
            ),
          ),
          dayProgressProvider.overrideWith(
            () => _Progress(
              DayProgress(
                readTypes: const {CardType.quote},
                visitedDays: const {},
                wisdomCompletedAt: now,
              ),
            ),
          ),
          completedCourseTopicsProvider.overrideWith((ref) async => {}),
        ],
        child: ReminderScheduler(clock: () => now, child: const SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    return analytics;
  }

  testWidgets('дневные напоминания на сегодня пишутся один раз за день', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'flutter.reminders_enabled': true});
    final prefs = await SharedPreferences.getInstance();

    final first = await pumpScheduler(tester, prefs);
    expect(first.single('daytime_reminders_scheduled'), {
      'story': true,
      'course': true,
    });

    // Перезапуск в тот же день пересобирает расписание, но не событие.
    await tester.pumpWidget(const SizedBox());
    final second = await pumpScheduler(tester, prefs);
    expect(second.names, isNot(contains('daytime_reminders_scheduled')));
  });
}
