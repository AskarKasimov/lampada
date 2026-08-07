import '../../../../core/result/result.dart';

/// Настройка напоминаний.
///
/// [asked] отделено от [enabled] намеренно: системный запрос разрешения iOS
/// показывает ровно один раз за установку, и повторно спросить нельзя. Поэтому
/// «ещё не спрашивали» и «спросили, отказался» — разные состояния: в первом
/// экран запроса надо показать, во втором нет.
class ReminderSettings {
  const ReminderSettings({required this.enabled, required this.asked});

  final bool enabled;
  final bool asked;

  static const initial = ReminderSettings(enabled: false, asked: false);
}

abstract interface class ReminderRepository {
  Future<Result<ReminderSettings>> load();

  Future<Result<ReminderSettings>> save(ReminderSettings settings);
}
