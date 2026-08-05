import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../domain/course_calendar.dart';
import '../../domain/repositories/course_progress_repository.dart';

/// Прогресс курса в shared_preferences: номер темы и день последнего сдвига.
class PrefsCourseProgressRepository implements CourseProgressRepository {
  PrefsCourseProgressRepository(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const _topicKey = 'course_topic';

  /// День, в который курс последний раз сдвинулся. Без него повторное открытие
  /// карточки за тот же день пролистывало бы курс вперёд.
  static const _advancedKey = 'course_topic_advanced_on';

  int get _topic => normalizeCourseTopic(_prefs.getInt(_topicKey) ?? 1);

  @override
  Future<Result<int>> currentTopic() async => _guard(() async => _topic);

  @override
  Future<Result<int>> advanceForToday() async => _guard(() async {
    final today = dateKey(_clock());
    if (_prefs.getString(_advancedKey) == today) return _topic;

    final next = normalizeCourseTopic(_topic + 1);
    await _prefs.setInt(_topicKey, next);
    await _prefs.setString(_advancedKey, today);
    return next;
  });

  Future<Result<int>> _guard(Future<int> Function() op) async {
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
