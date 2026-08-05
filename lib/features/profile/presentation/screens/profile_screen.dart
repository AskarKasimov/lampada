import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../widgets/theme_mode_toggle_button.dart';

/// Вкладка «Профиль»: настройки приложения. Напоминания приезжают вместе с
/// пушами; аккаунта и подписки в бесплатном пилоте нет вовсе (FR-024).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, kFloatingNavInset),
      children: [
        Text(
          'ПРОФИЛЬ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
            color: colors.todayLabel,
          ),
        ),
        const SizedBox(height: 20),
        const ThemeModeSettingTile(),
        const SizedBox(height: 32),
        // FR-025: контент принадлежит Азбуке, и это должно быть видно
        // не только мелкой подписью под карточкой.
        Text(
          'Контент дня — материалы портала «Азбука веры» (azbyka.ru).',
          style: TextStyle(fontSize: 12, height: 1.5, color: colors.homeSubtitle),
        ),
      ],
    );
  }
}
