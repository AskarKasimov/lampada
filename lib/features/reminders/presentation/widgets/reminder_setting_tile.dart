import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/providers.dart';

/// Тумблер напоминаний в Профиле.
///
/// Нужен даже при том, что разрешение спрашивается после первой карточки:
/// отказавшийся там должен иметь способ передумать, а согласившийся —
/// выключить, не уходя в Настройки iOS.
class ReminderSettingTile extends ConsumerWidget {
  const ReminderSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final settings = ref.watch(reminderSettingsProvider).value;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Напоминания',
                style: TextStyle(fontSize: 15, color: colors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                'Пока день не открыт',
                style: TextStyle(fontSize: 12, color: colors.homeSubtitle),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: settings?.enabled ?? false,
          onChanged: settings == null
              ? null
              : (value) => ref
                    .read(reminderSettingsProvider.notifier)
                    .setEnabled(enabled: value),
        ),
      ],
    );
  }
}
