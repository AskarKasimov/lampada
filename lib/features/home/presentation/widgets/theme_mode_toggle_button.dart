import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_mode_provider.dart';

/// Иконка-тумблер режима темы в углу Home: тап циклит
/// системный → светлый → тёмный → системный режим. Каждый режим —
/// своя иконка (не резолвится в текущую яркость), иначе «системный»
/// на светлой платформе неотличим от явного «светлого».
class ThemeModeToggleButton extends ConsumerWidget {
  const ThemeModeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };

    return IconButton(
      onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
      icon: Icon(icon, color: AppColorsExtension.of(context).homeIcon),
      tooltip: 'Тема: ${_label(mode)}',
    );
  }

  String _label(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'системная',
        ThemeMode.light => 'светлая',
        ThemeMode.dark => 'тёмная',
      };
}
