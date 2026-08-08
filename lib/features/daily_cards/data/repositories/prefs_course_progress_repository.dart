import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../domain/course_calendar.dart';
import '../../domain/repositories/course_progress_repository.dart';

/// Прогресс курса в shared_preferences: номер текущей темы и день её прочтения.
class PrefsCourseProgressRepository implements CourseProgressRepository {
  PrefsCourseProgressRepository(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const _topicKey = 'course_topic_v2';

  /// Тема не меняется в день прочтения. На следующий день [currentTopic]
  /// увидит эту отметку и откроет одну следующую тему.
  static const _readOnKey = 'course_topic_read_on_v2';

  int get _topic => normalizeCourseTopic(_prefs.getInt(_topicKey) ?? 1);

  @override
  Future<Result<int>> currentTopic() => _guard(() async {
    final today = dateKey(_clock());
    final readOn = _prefs.getString(_readOnKey);
    if (readOn == null || readOn.compareTo(today) >= 0) return _topic;

    final next = normalizeCourseTopic(_topic + 1);
    await _prefs.setInt(_topicKey, next);
    await _prefs.remove(_readOnKey);
    return next;
  });

  @override
  Future<Result<void>> markCurrentTopicRead() => _guard(() async {
    await _prefs.setString(_readOnKey, dateKey(_clock()));
  });

  Future<Result<T>> _guard<T>(Future<T> Function() op) async {
    try {
      return Success(await op());
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать прогресс курса',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
