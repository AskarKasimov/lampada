import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics.dart';
import 'appmetrica_analytics.dart';

/// Тесты подменяют провайдер фейком, который записывает события.
final analyticsProvider = Provider<Analytics>(
  (ref) => const AppMetricaAnalytics(),
);
