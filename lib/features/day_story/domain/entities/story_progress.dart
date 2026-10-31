import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/format/date_key.dart';

part 'story_progress.freezed.dart';

/// Прочитанные рассказы «Памяти дня».
@freezed
abstract class StoryProgress with _$StoryProgress {
  const factory StoryProgress({
    /// Дни (yyyy-MM-dd), в которые прочитан хотя бы один рассказ: тому, кто
    /// уже читал, напоминание о святом не приходит.
    @Default(<String>{}) Set<String> readDays,

    /// Ссылки прочитанных рассказов по дням: по ним плитка переходит к
    /// следующему святому дня.
    @Default(<String, Set<String>>{}) Map<String, Set<String>> readStories,
  }) = _StoryProgress;

  const StoryProgress._();

  /// Ссылки рассказов, прочитанных за [date].
  Set<String> readOn(DateTime date) => readStories[dateKey(date)] ?? const {};
}
