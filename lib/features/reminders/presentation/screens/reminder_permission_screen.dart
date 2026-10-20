import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../providers/providers.dart';

/// Запрос разрешения на уведомления — ПОСЛЕ первой прочитанной карточки.
///
/// Момент выбран не случайно: iOS показывает системный запрос ровно один раз
/// за установку. Потратить его на холодный старт, когда человек ещё ничего не
/// получил, — значит с большой вероятностью получить отказ навсегда. Здесь он
/// уже прочитал цитату, и «завтра будет новая» — не просьба, а продолжение.
class ReminderPermissionScreen extends ConsumerStatefulWidget {
  const ReminderPermissionScreen({
    super.key,
    this.trigger = ReminderPromptTrigger.wisdom,
  });

  /// После чего показан экран: аналитика сравнивает согласия по источнику.
  final ReminderPromptTrigger trigger;

  @override
  ConsumerState<ReminderPermissionScreen> createState() =>
      _ReminderPermissionScreenState();
}

class _ReminderPermissionScreenState
    extends ConsumerState<ReminderPermissionScreen> {
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _log(AnalyticsEvent.reminderPromptShown(widget.trigger));
  }

  void _log(AnalyticsEvent event) => ref.read(analyticsProvider).log(event);

  void _answer(ReminderPromptChoice choice, {bool? osGranted}) {
    _answered = true;
    _log(
      AnalyticsEvent.reminderPromptAnswered(
        choice: choice,
        osGranted: osGranted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    void close() => Navigator.of(context).pop();

    // Системный «назад» на Android закрывает экран без ответа; он покажется
    // снова, но в отчёте это отдельный исход.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_answered) _answer(ReminderPromptChoice.dismissed);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding:
                AppSpacing.of(context).horizontal +
                const EdgeInsets.only(top: 24, bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                // Цифра из метаанализа Thakkar et al., JAMA Intern Med 2016:
                // с напоминаниями режим соблюдали 67,8% против 50%.
                Text(
                  'С напоминаниями ежедневную привычку держат на 36% чаще',
                  style: AppTheme.quoteStyle(
                    context,
                  ).copyWith(fontSize: 30, height: 1.25),
                ),
                const SizedBox(height: 14),
                Text(
                  'Перестаньте сидеть в соцсетях: вместо этого каждый день '
                  'изучайте Библию, мудрость и жития святых.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(flex: 3),
                Center(
                  child: Column(
                    children: [
                      AppPrimaryButton(
                        label: 'Напоминать',
                        color: colors.accent,
                        onPressed: () async {
                          final granted = await notifier.requestAndEnable();
                          _answer(
                            ReminderPromptChoice.allow,
                            osGranted: granted,
                          );
                          if (context.mounted) close();
                        },
                      ),
                      const SizedBox(height: 6),
                      // Тихо и низкоконтрастно: отказ не должен выглядеть
                      // равноценным выбором, но и прятать его нечестно.
                      AppLinkButton(
                        label: 'Не сейчас',
                        color: colors.homeSubtitle,
                        fontSize: 13,
                        onPressed: () async {
                          _answer(ReminderPromptChoice.later);
                          await notifier.declineForNow();
                          if (context.mounted) close();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
