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
    _listener = AppLifecycleListener(onResume: _refresh);
  }

  /// Перезапрашиваем безусловно. Соблазн дёргать провайдер только при ошибке
  /// или при `staleDate != null` — ложная экономия: набор, полученный вчера за
  /// вчера, выглядит совершенно свежим, а по самому [TodayCards] дату, за
  /// которую он взят, не узнать. С таким гейтом приложение, пролежавшее ночь
  /// в фоне, показывало бы вчерашний контент как сегодняшний, без пометки, и
  /// с невыброшенным вчерашним прогрессом.
  ///
  /// Платить за это почти нечем: при совпадении даты репозиторий отдаёт кэш и
  /// в сеть не ходит, а `loadToday` заодно сбрасывает прочитанное за прошлый
  /// день.
  void _refresh() {
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
