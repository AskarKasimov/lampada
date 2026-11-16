import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/entities/story_progress.dart';
import '../../domain/repositories/story_progress_repository.dart';

/// Хранит прочитанные рассказы в shared_preferences: дни списком дат и
/// рассказы списком строк «yyyy-MM-dd ссылка».
class PrefsStoryProgressRepository implements StoryProgressRepository {
  PrefsStoryProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _daysKey = 'story_read_days';
  static const _storiesKey = 'story_read_urls';

  /// Как и у прогресса дня: prefs не база, держим чуть больше года.
  static const _maxDays = 400;

  StoryProgress _read() {
    final stories = <String, Set<String>>{};
    for (final entry in _prefs.getStringList(_storiesKey) ?? const <String>[]) {
      final space = entry.indexOf(' ');
      if (space < 0) continue;
      (stories[entry.substring(0, space)] ??= {}).add(
        entry.substring(space + 1),
      );
    }
    return StoryProgress(
      readDays: {...?_prefs.getStringList(_daysKey)},
      readStories: stories,
    );
  }

  @override
  Future<Result<StoryProgress>> load() async {
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
  Future<Result<StoryProgress>> markRead(DateTime date, String storyUrl) async {
    try {
      final current = _read();
      final day = dateKey(date);
      final days = ({...current.readDays, day}.toList()..sort());
      final kept = days.length > _maxDays
          ? days.sublist(days.length - _maxDays)
          : days;
      final keptDays = kept.toSet();
      final stories = {
        for (final MapEntry(:key, :value) in {
          ...current.readStories,
          day: {...current.readOn(date), storyUrl},
        }.entries)
          if (keptDays.contains(key)) key: value,
      };
      final entries = [
        for (final MapEntry(:key, :value) in stories.entries)
          for (final url in value) '$key $url',
      ]..sort();
      await requirePreferenceWrite(_prefs.setStringList(_daysKey, kept));
      await requirePreferenceWrite(_prefs.setStringList(_storiesKey, entries));
      return Success(StoryProgress(readDays: keptDays, readStories: stories));
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
