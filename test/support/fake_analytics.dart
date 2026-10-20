import 'package:lampada/core/analytics/analytics.dart';
import 'package:lampada/core/analytics/analytics_event.dart';

/// Записывает события вместо отправки в AppMetrica.
class FakeAnalytics implements Analytics {
  final events = <AnalyticsEvent>[];
  final profiles = <AnalyticsProfile>[];

  @override
  void log(AnalyticsEvent event) => events.add(event);

  @override
  void setProfile(AnalyticsProfile profile) => profiles.add(profile);

  Iterable<String> get names => events.map((e) => e.name);

  /// Параметры единственного события [name]; падает, если их не одно.
  Map<String, Object> single(String name) =>
      events.singleWhere((e) => e.name == name).params;
}
