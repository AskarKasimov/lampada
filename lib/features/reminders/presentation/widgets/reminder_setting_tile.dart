import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

    void setEnabled(bool value) {
      ref.read(reminderSettingsProvider.notifier).setEnabled(enabled: value);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: settings == null ? null : () => setEnabled(!settings.enabled),
        child: Padding(
          padding:
              AppSpacing.of(context).horizontal +
              const EdgeInsets.symmetric(vertical: 8),
          child: Row(
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
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.homeSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: settings?.enabled ?? false,
                onChanged: settings == null ? null : setEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
