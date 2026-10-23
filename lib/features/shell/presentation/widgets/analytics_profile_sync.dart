import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../bible/presentation/providers/providers.dart';
import '../../../bookmarks/presentation/providers/providers.dart';
import '../../../daily_cards/presentation/providers/providers.dart';
import '../../../reminders/presentation/providers/providers.dart';

/// Держит обезличенные атрибуты профиля AppMetrica в согласии с состоянием
/// приложения: серия, пройденное, уведомления, тема. Живёт в шелле рядом с
/// расписанием напоминаний, потому что собирает данные всех фич.
class AnalyticsProfileSync extends ConsumerStatefulWidget {
  const AnalyticsProfileSync({
    required this.child,
    super.key,
    this.clock = DateTime.now,
  });

  final Widget child;

  /// Подменяется в тестах: серия считается на сегодняшний день.
  final DateTime Function() clock;

  @override
  ConsumerState<AnalyticsProfileSync> createState() =>
      _AnalyticsProfileSyncState();
}

class _AnalyticsProfileSyncState extends ConsumerState<AnalyticsProfileSync> {
  AnalyticsProfile? _lastSent;

  /// Разрешение ОС: юзер мог выключить уведомления в настройках мимо
  /// приложения. Спрашиваем на старте и при смене настройки.
  bool? _permitted;

  Future<void> _refreshPermission() async {
    final permitted = await ref
        .read(notificationServiceProvider)
        .isPermitted()
        .catchError((Object _) => false);
    if (!mounted) return;
    _permitted = permitted;
    _sync();
  }

  void _sync() {
    final today = widget.clock();
    final progress = ref.read(dayProgressProvider).value;
    final profile = AnalyticsProfile(
      notificationsEnabled: ref.read(reminderSettingsProvider).value?.enabled,
      notificationsPermitted: _permitted,
      streak: progress?.streakOn(today),
      wisdomDaysTotal: progress?.wisdomCompletedDays.length,
      courseTopicsCompleted: ref
          .read(completedCourseTopicsProvider)
          .value
          ?.length,
      bibleChaptersRead: ref
          .read(bibleChapterStatusesProvider)
          .value
          ?.read
          .length,
      bookmarksCount: ref.read(bookmarksProvider).value?.length,
      theme: ref.read(themeModeProvider).name,
    );
    if (profile == _lastSent) return;
    _lastSent = profile;
    ref.read(analyticsProvider).setProfile(profile);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshPermission());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(dayProgressProvider, (_, _) => _sync())
      ..listen(completedCourseTopicsProvider, (_, _) => _sync())
      ..listen(bibleChapterStatusesProvider, (_, _) => _sync())
      ..listen(bookmarksProvider, (_, _) => _sync())
      ..listen(themeModeProvider, (_, _) => _sync())
      ..listen(
        reminderSettingsProvider,
        (_, _) => unawaited(_refreshPermission()),
      );
    return widget.child;
  }
}
