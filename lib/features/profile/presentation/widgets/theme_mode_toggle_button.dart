import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_mode_provider.dart';

/// Выбор темы в Профиле: система / светлая / тёмная.
///
/// Раньше это был двухпозиционный тумблер «Тёмная тема», и системного варианта
/// не существовало: один раз переключив, юзер навсегда отвязывался от
/// системной темы и вернуть связь было нечем.
class ThemeModeSettingTile extends ConsumerWidget {
  const ThemeModeSettingTile({super.key});

  static const _labels = {
    ThemeMode.system: 'Система',
    ThemeMode.light: 'Светлая',
    ThemeMode.dark: 'Тёмная',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final colors = AppColorsExtension.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Тема', style: TextStyle(fontSize: 15, color: colors.ink)),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: [
            for (final entry in _labels.entries)
              ButtonSegment(value: entry.key, label: Text(entry.value)),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              ref.read(themeModeProvider.notifier).select(selection.first),
          style: SegmentedButton.styleFrom(
            foregroundColor: colors.textSecondary,
            selectedForegroundColor: colors.background,
            selectedBackgroundColor: colors.accent,
            side: BorderSide(color: colors.chipUnreadBorder),
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
