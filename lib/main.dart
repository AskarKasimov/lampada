import 'dart:async';

import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/analytics/analytics_event.dart';
import 'core/analytics/analytics_provider.dart';
import 'core/storage/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/daily_cards/presentation/providers/providers.dart';
import 'features/daily_cards/presentation/widgets/refresh_on_resume.dart';
import 'features/reminders/domain/usecases/plan_reminders.dart';
import 'features/reminders/presentation/providers/providers.dart';
import 'features/shell/presentation/providers/shell_providers.dart';
import 'features/shell/presentation/screens/splash_screen.dart';

/// Ключ SDK AppMetrica. Не секрет: он и так лежит в каждой сборке.
const _appMetricaApiKey = '7de1fcc9-da6e-4bc5-a828-e8238be0f32f';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Как можно раньше: SDK вешается на FlutterError.onError и считает сессию
  // с холодного старта. Не ждём ответа нативной части, чтобы не тормозить
  // запуск. Геолокацию и рекламные идентификаторы не собираем: приложению
  // они не нужны, а AD_ID на Android ещё и вырезан из манифеста.
  unawaited(
    AppMetrica.activate(
      const AppMetricaConfig(
        _appMetricaApiKey,
        locationTracking: false,
        advIdentifiersTracking: false,
        logs: kDebugMode,
      ),
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Тап по напоминанию ведёт на «Сегодня» и сразу в раздел, о котором оно
  // звало, где бы юзер ни был в прошлый раз (FR-015). Разрешение здесь НЕ
  // запрашиваем: это делает отдельный экран после первой карточки.
  await container
      .read(notificationServiceProvider)
      .init(
        onTap: (tap) {
          container.read(selectedTabProvider.notifier).select(ShellTab.today);
          container
              .read(openDaySectionRequestProvider.notifier)
              .request(tap.section, origin: SectionRequestOrigin.notification);
          container
              .read(analyticsProvider)
              .log(
                AnalyticsEvent.notificationOpened(
                  section: AnalyticsSection.values.byName(tap.section.name),
                  slot: ReminderSlot.values.byName(
                    slotOfReminderId(tap.id).name,
                  ),
                  coldStart: tap.coldStart,
                ),
              );
        },
      );

  runApp(
    UncontrolledProviderScope(container: container, child: const LampadaApp()),
  );
}

class LampadaApp extends ConsumerWidget {
  const LampadaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Лампада',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // Через builder, а не обёрткой вокруг home: сплэш уходит на Home
      // через pushReplacement, и обёртка вокруг home: умерла бы вместе с
      // маршрутом сплэша. builder оборачивает Navigator и живёт всегда.
      builder: (context, child) => RefreshOnResume(child: child!),
      home: const SplashScreen(),
    );
  }
}
