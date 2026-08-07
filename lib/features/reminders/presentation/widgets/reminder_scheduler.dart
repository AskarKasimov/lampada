import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../daily_cards/presentation/providers/providers.dart';
import '../providers/providers.dart';

/// Держит системное расписание напоминаний в согласии с прогрессом.
///
/// Пересчитывает при каждом изменении прочитанного и состава дня: напоминаем
/// только о том, до чего юзер не дошёл, поэтому прочитанная карточка обязана
/// снимать своё напоминание сразу, а не завтра. Локальные уведомления живут
/// в системе и сами о прогрессе не знают.
class ReminderScheduler extends ConsumerStatefulWidget {
  const ReminderScheduler({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ReminderScheduler> createState() => _ReminderSchedulerState();
}

class _ReminderSchedulerState extends ConsumerState<ReminderScheduler> {
  /// Последнее отправленное в систему расписание — чтобы не дёргать плагин
  /// на каждый ребилд с тем же результатом.
  String? _lastPlan;

  Future<void> _reschedule() async {
    final settings = ref.read(reminderSettingsProvider).value;
    final service = ref.read(notificationServiceProvider);

    if (settings == null || !settings.enabled) {
      if (_lastPlan != null) {
        _lastPlan = null;
        await service.cancelAll();
      }
      return;
    }

    final day = ref.read(todayCardsProvider).value;
    final progress = ref.read(dayProgressProvider).value;
    if (day == null || progress == null) return;

    final plan = planReminders(
      now: DateTime.now(),
      readToday: progress.readTypes,
      sections: day.cards.map((c) => c.type).toList(),
    );

    final signature = plan.map((r) => '${r.id}@${r.at}:${r.title}').join('|');
    if (signature == _lastPlan) return;
    _lastPlan = signature;
    await service.schedule(plan);
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(dayProgressProvider, (_, _) => _reschedule())
      ..listen(todayCardsProvider, (_, _) => _reschedule())
      ..listen(reminderSettingsProvider, (_, _) => _reschedule());

    // Первый расчёт: слушатели срабатывают только на ИЗМЕНЕНИЯ, а к моменту
    // построения шелла и день, и прогресс обычно уже загружены сплэшем.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reschedule());

    return widget.child;
  }
}
