import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/analytics/analytics.dart';
import 'package:lampada/core/analytics/analytics_event.dart';
import 'package:lampada/core/analytics/appmetrica_analytics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('без нативного SDK событие не роняет приложение', () async {
    // В тестах и при сбое SDK платформенный вызов падает; аналитика не
    // должна превращать это в необработанную ошибку.
    const analytics = AppMetricaAnalytics();

    analytics
      ..log(AnalyticsEvent.onboardingCompleted())
      ..log(AnalyticsEvent.tabOpened(AnalyticsTab.bible))
      ..setProfile(const AnalyticsProfile(streak: 3, theme: 'dark'));
    await Future<void>.delayed(Duration.zero);
  });
}
