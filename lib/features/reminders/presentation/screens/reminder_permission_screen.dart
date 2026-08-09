import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
class ReminderPermissionScreen extends ConsumerWidget {
  const ReminderPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    void close() => Navigator.of(context).pop();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // Заголовок — ПРИЧИНА согласиться, и причина конкретная:
              // и курс, и чтение идут по шагу в день, поэтому пропуск дня
              // останавливает начатое. Про то, что мы будем делать, здесь
              // не сказано ни слова — это было прошлой ошибкой.
              Text(
                'Чтобы не остановиться\nна первом дне',
                style: AppTheme.quoteStyle(
                  context,
                ).copyWith(fontSize: 30, height: 1.25),
              ),
              const SizedBox(height: 14),
              // Механика ушла в конец второй строки и отвечает там на
              // возражение «вы меня закидаете уведомлениями».
              Text(
                'Курс и чтение идут по шагу в день — без напоминания их '
                'обычно пропускают. Одно в день, тихо, и только пока день '
                'не открыт.',
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
                        await notifier.requestAndEnable();
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
    );
  }
}
