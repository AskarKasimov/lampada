import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Перезапрашивает карточки, когда юзер возвращается в приложение.
///
/// Закрывает ровно тот путь, который провоцирует офлайн-состояние: увидел
/// «включите Wi-Fi» → ушёл в Настройки → вернулся. Жать «Повторить» после
/// этого не нужно. Репозиторий перед сетевым запросом сам быстро отсекает
/// явный офлайн через общий статус сети.
class RefreshOnResume extends ConsumerStatefulWidget {
  const RefreshOnResume({required this.child, super.key});

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

  /// Перезапрашиваем безусловно: пока приложение было в фоне, календарный
  /// день мог смениться.
  ///
  /// Платить за безусловность почти нечем: при совпадении даты репозиторий
  /// отдаёт кэш без похода в сеть, а `loadToday` заодно сбрасывает
  /// прочитанное за прошлый день.
  /// Инвалидируем саму family, а не обёртку [todayCardsProvider]: обёртка
  /// лишь читает `dayCardsProvider(сегодня)`, и её сброс перечитал бы тот же
  /// закэшированный инстанс, не сходив в сеть.
  void _refresh() {
    ref.invalidate(dayCardsProvider);
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
