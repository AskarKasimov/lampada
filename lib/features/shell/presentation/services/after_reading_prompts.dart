import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/navigation/bottom_up_modal_route.dart';
import '../../../profile/domain/repositories/review_prompt_repository.dart';
import '../../../profile/presentation/providers/providers.dart';
import '../../../reminders/domain/repositories/reminder_repository.dart';
import '../../../reminders/presentation/providers/providers.dart';
import '../../../reminders/presentation/screens/reminder_permission_screen.dart';

/// Юзер закрыл раздел, дочитав его или нет. Первое такое закрытие —
/// момент спросить про напоминания, затем попросить оценку: человек уже
/// увидел, ради чего приложение, и чтение не прерывается. Оценку просим
/// ещё раз при первом закрытии раздела в один из следующих дней, если в
/// этот день её ещё не просили.
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
  final moment = await ref.read(claimReviewRequestProvider).afterReading();
  if (moment == null || !context.mounted) return;
  await _requestReview(ref, moment);
}

/// Юзер открыл приложение (холодным стартом или из фона). В любой из дней
/// после первого входа один раз сразу просим оценку. Если при этом входе
/// уже встало системное окно уведомлений ([remindersAsked]), оценку не
/// ставим вторым окном подряд, а только запоминаем вход.
Future<void> askReviewOnOpen(
  BuildContext context, {
  required bool remindersAsked,
}) async {
  final ref = ProviderScope.containerOf(context, listen: false);
  final claim = ref.read(claimReviewRequestProvider);
  if (remindersAsked) {
    await claim.recordAppOpen();
    return;
  }
  if (!await claim.afterAppOpen() || !context.mounted) return;
  await _requestReview(ref, ReviewMoment.laterDayOpen);
}

Future<void> _requestReview(ProviderContainer ref, ReviewMoment moment) async {
  ref
      .read(analyticsProvider)
      .log(
        AnalyticsEvent.reviewRequested(switch (moment) {
          ReviewMoment.firstReading => ReviewTrigger.firstReading,
          ReviewMoment.nextDayReturn => ReviewTrigger.nextDay,
          ReviewMoment.laterDayOpen => ReviewTrigger.appOpen,
        }),
      );
  await ref.read(profileActionsServiceProvider).requestReview();
}

/// Юзер вернулся в приложение в один из дней после первого входа. Если
/// напоминания не включены и система их ещё не разрешила, один раз сразу
/// показываем системное окно, без нашего экрана: кто отложил напоминания
/// после первого чтения, его не видел. Разрешение включает напоминания так
/// же, как кнопка «Напоминать».
///
/// Возвращает, показали ли системное окно: тогда оценку при этом входе не
/// просим, чтобы два окна не встали подряд.
Future<bool> askRemindersOnReturn(BuildContext context) async {
  final ref = ProviderScope.containerOf(context, listen: false);
  final ReminderSettings settings;
  try {
    settings = await ref.read(reminderSettingsProvider.future);
  } on Object {
    return false;
  }
  // Момент отмечается и тогда, когда спрашивать не нужно: напоминания уже
  // включены или выключены в Профиле при разрешении системы.
  if (!await ref.read(claimReturnReminderPromptProvider)()) return false;
  if (settings.enabled) return false;
  final notifications = ref.read(notificationServiceProvider);
  if (await notifications.isPermitted()) return false;
  final analytics = ref.read(analyticsProvider)
    ..log(AnalyticsEvent.reminderPromptShown(ReminderPromptTrigger.nextDay));
  final granted = await ref
      .read(reminderSettingsProvider.notifier)
      .requestAndEnable();
  analytics.log(
    AnalyticsEvent.reminderPromptAnswered(
      choice: ReminderPromptChoice.system,
      osGranted: granted,
    ),
  );
  return true;
}
