import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/course_calendar.dart';
import '../../domain/repositories/course_progress_repository.dart';

/// Место чтения и отметки завершения хранятся отдельно в одной записи.
class PrefsCourseProgressRepository implements CourseProgressRepository {
  PrefsCourseProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  // Старый номер — только место чтения. Отсутствие completedTopics не даёт
  // оснований засчитывать все предыдущие темы: они могли быть пролистаны.
  static const _key = 'course_progress_v4';
  bool _cacheNeedsReload = false;

  Future<Map<String, dynamic>> _read() async {
    if (_cacheNeedsReload) {
      await _prefs.reload();
      _cacheNeedsReload = false;
    }
    final raw = _prefs.getString(_key);
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  Set<int> _completedFrom(Map<String, dynamic> json) {
    final topics = (json['completedTopics'] as List<dynamic>? ?? [])
        .cast<int>()
        .toSet();
    if (topics.any((topic) => topic < 1 || topic > courseTopicCount)) {
      throw const FormatException('Некорректный номер завершённой темы');
    }
    return Set.unmodifiable(topics);
  }

  Future<void> _write(Map<String, dynamic> json) async {
    // SharedPreferences меняет кэш до ответа платформы. После ошибки читаем
    // подтверждённое состояние; сбой reload оставляет повторную попытку.
    _cacheNeedsReload = true;
    await requirePreferenceWrite(_prefs.setString(_key, jsonEncode(json)));
    _cacheNeedsReload = false;
  }

  @override
  Future<Result<int>> currentTopic() async {
    await _writing;
    return _guard(
      () async => normalizeCourseTopic((await _read())['topic'] as int? ?? 1),
    );
  }

  @override
  Future<Result<Set<int>>> completedTopics() async {
    await _writing;
    return _guard(() async => _completedFrom(await _read()));
  }

  /// Записи выстраиваются в очередь, поэтому быстрые свайпы сохраняют тему
  /// в том же порядке, в котором юзер их видел.
  Future<Result<void>> _writing = Future.value(const Success(null));

  @override
  Future<Result<void>> saveCurrentTopic(int topic) => _writing = _writing.then(
    (_) => _guard(
      () async =>
          _write({...await _read(), 'topic': normalizeCourseTopic(topic)}),
    ),
  );

  @override
  Future<Result<void>> completeTopic(int topic) => _writing = _writing.then(
    (_) => _guard(() async {
      final json = await _read();
      final completed = {..._completedFrom(json), topic}.toList()..sort();
      return _write({...json, 'completedTopics': completed});
    }),
  );

  Future<Result<T>> _guard<T>(Future<T> Function() op) async {
    try {
      return Success(await op());
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось загрузить или сохранить прогресс курса',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
