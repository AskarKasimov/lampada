import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/course_calendar.dart';
import '../../domain/repositories/course_progress_repository.dart';

/// Прогресс курса в shared_preferences: номер текущей темы и день её прочтения.
class PrefsCourseProgressRepository implements CourseProgressRepository {
  PrefsCourseProgressRepository(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const _key = 'course_progress_v3';

  _CourseProgress _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const _CourseProgress(topic: 1);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _CourseProgress(
      topic: normalizeCourseTopic(json['topic'] as int? ?? 1),
      readOn: json['readOn'] as String?,
    );
  }

  Future<void> _write(_CourseProgress progress) => requirePreferenceWrite(
    _prefs.setString(
      _key,
      jsonEncode({'topic': progress.topic, 'readOn': progress.readOn}),
    ),
  );

  @override
  Future<Result<int>> currentTopic() => _guard(() async {
    final today = dateKey(_clock());
    final progress = _read();
    if (progress.readOn == null || progress.readOn!.compareTo(today) >= 0) {
      return progress.topic;
    }

    final next = normalizeCourseTopic(progress.topic + 1);
    await _write(_CourseProgress(topic: next));
    return next;
  });

  @override
  Future<Result<void>> markCurrentTopicRead() => _guard(() async {
    final progress = _read();
    await _write(progress.copyWith(readOn: dateKey(_clock())));
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

class _CourseProgress {
  const _CourseProgress({required this.topic, this.readOn});

  final int topic;
  final String? readOn;

  _CourseProgress copyWith({String? readOn}) =>
      _CourseProgress(topic: topic, readOn: readOn);
}
