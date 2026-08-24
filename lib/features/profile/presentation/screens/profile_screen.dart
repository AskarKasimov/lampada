import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reminders/presentation/widgets/reminder_setting_tile.dart';
import '../../../shell/presentation/widgets/floating_nav_bar.dart';
import '../providers/providers.dart';
import '../widgets/profile_link_tile.dart';
import '../widgets/theme_mode_toggle_button.dart';

/// Ссылки на документы — за пределами кода: разработчик разместил их
/// на отдельном сайте и может обновлять без правки приложения.
const _privacyPolicyUrl =
    'https://sites.google.com/view/lampada-privacy-policy/'
    '%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F-%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0';
const _termsOfUseUrl = 'https://sites.google.com/view/lampada-terms-of-use/';

/// Вкладка «Профиль»: настройки приложения. Аккаунта и подписки
/// в бесплатном пилоте нет вовсе (FR-024).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final actions = ref.read(profileActionsServiceProvider);

    Future<void> requestReview() async {
      final opened = await actions.requestReview();
      if (opened || !context.mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть форму отзыва'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

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
        const SizedBox(height: 24),
        const ReminderSettingTile(),
        const SizedBox(height: 28),
        ProfileLinkTile(
          label: 'Поделиться приложением',
          onTap: actions.shareApp,
        ),
        ProfileLinkTile(label: actions.reviewLabel, onTap: requestReview),
        ProfileLinkTile(
          label: 'Политика конфиденциальности',
          onTap: () => actions.openUrl(_privacyPolicyUrl),
        ),
        ProfileLinkTile(
          label: 'Условия использования',
          onTap: () => actions.openUrl(_termsOfUseUrl),
        ),
        const SizedBox(height: 24),
        // FR-025: контент принадлежит Азбуке, и это должно быть видно
        // не только мелкой подписью под карточкой.
        Text(
          'Контент дня — материалы портала «Азбука веры» (azbyka.ru).',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: colors.homeSubtitle,
          ),
        ),
      ],
    );
  }
}
