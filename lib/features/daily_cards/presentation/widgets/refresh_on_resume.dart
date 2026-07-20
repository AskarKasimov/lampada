import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Перезапрашивает карточки, когда юзер возвращается в приложение.
///
/// Закрывает ровно тот путь, который провоцирует офлайн-состояние: увидел
/// «включите Wi-Fi» → ушёл в Настройки → вернулся. Жать «Повторить» после
/// этого не нужно. `connectivity_plus` ради этого не заводим — жизненного
/// цикла достаточно.
class RefreshOnResume extends ConsumerStatefulWidget {
  const RefreshOnResume({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RefreshOnResume> createState() => _RefreshOnResumeState();
}

class _RefreshOnResumeState extends ConsumerState<RefreshOnResume> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _refreshIfStale);
  }

  /// Инвалидируем только когда есть что чинить — иначе каждое открытие
  /// приложения дёргало бы провайдер впустую.
  void _refreshIfStale() {
    final cards = ref.read(todayCardsProvider);
    final needsRefresh = cards.hasError || cards.value?.staleDate != null;
    if (!needsRefresh) return;
    ref.invalidate(todayCardsProvider);
    ref.invalidate(dayProgressProvider);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
