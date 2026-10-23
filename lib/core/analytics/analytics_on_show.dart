import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_event.dart';
import 'analytics_provider.dart';

/// Пишет событие один раз, когда виджет впервые показан: экран ошибки
/// перестраивается много раз, а показ должен считаться одним.
class AnalyticsOnShow extends ConsumerStatefulWidget {
  const AnalyticsOnShow({required this.event, required this.child, super.key});

  final AnalyticsEvent event;
  final Widget child;

  @override
  ConsumerState<AnalyticsOnShow> createState() => _AnalyticsOnShowState();
}

class _AnalyticsOnShowState extends ConsumerState<AnalyticsOnShow> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).log(widget.event);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
