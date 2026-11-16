import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/navigation/bottom_up_modal_route.dart';
import '../../../profile/presentation/providers/providers.dart';
import '../../../reminders/presentation/providers/providers.dart';
import '../../../reminders/presentation/screens/reminder_permission_screen.dart';

/// Юзер закрыл раздел, дочитав его или нет. Первое такое закрытие —
/// момент спросить про напоминания, затем попросить оценку: человек уже
/// увидел, ради чего приложение, и чтение не прерывается. Оба запроса
/// срабатывают по разу; повторные закрытия ничего не показывают.
///
/// Вызывается, когда раздел уже закрыт: после итога с лампадой, а не поверх
/// него.
///
/// Контейнер провайдеров берётся из [context]: так обработчик зовут и экраны
/// без `WidgetRef`, например открытие просмотра Библии.
Future<void> askAfterReading(
  BuildContext context,
  ReminderPromptTrigger trigger,
) async {
  final ref = ProviderScope.containerOf(context, listen: false);
  bool asked;
  try {
    // Настройка сохраняется асинхронно, поэтому ждём провайдер, а не value.
    asked = (await ref.read(reminderSettingsProvider.future)).asked;
  } on Object {
    // Без настройки не знаем, спрашивали ли: лишний запрос хуже пропуска.
    asked = true;
  }
  if (!context.mounted) return;
  if (!asked) {
    // Вопрос о разрешении накрывает весь шелл, вместе с навбаром.
    await Navigator.of(context, rootNavigator: true).push(
      BottomUpModalRoute<void>(
        builder: (_) => ReminderPermissionScreen(trigger: trigger),
      ),
    );
    if (!context.mounted) return;
  }
  if (!await ref.read(claimReviewRequestProvider).afterReading()) return;
  if (!context.mounted) return;
  ref
      .read(analyticsProvider)
      .log(AnalyticsEvent.reviewRequested(ReviewTrigger.firstReading));
  await ref.read(profileActionsServiceProvider).requestReview();
}
