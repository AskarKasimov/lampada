import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/repositories/story_progress_repository.dart';

/// Хранит дни прочитанных рассказов списком дат в shared_preferences.
class PrefsStoryProgressRepository implements StoryProgressRepository {
  PrefsStoryProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'story_read_days';

  /// Как и у прогресса дня: prefs не база, держим чуть больше года.
  static const _maxDays = 400;

  Set<String> _read() => {...?_prefs.getStringList(_key)};

  @override
  Future<Result<Set<String>>> readDays() async {
    try {
      return Success(_read());
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось загрузить прочитанные рассказы',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<Set<String>>> markRead(DateTime date) async {
    try {
      final days = ({..._read(), dateKey(date)}.toList()..sort());
      final kept = days.length > _maxDays
          ? days.sublist(days.length - _maxDays)
          : days;
      await requirePreferenceWrite(_prefs.setStringList(_key, kept));
      return Success(kept.toSet());
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось отметить рассказ прочитанным',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
