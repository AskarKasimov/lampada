import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/course_calendar.dart';
import '../../domain/repositories/course_progress_repository.dart';

/// Прогресс курса в shared_preferences: номер последней открытой темы.
///
/// Ограничения «не больше темы в день» нет: сколько тем прочитать за раз,
/// решает юзер. Поэтому день последнего сдвига не хранится.
class PrefsCourseProgressRepository implements CourseProgressRepository {
  PrefsCourseProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  // Предыдущая схема отмечала прочтение, но оставляла тему прежней до завтра.
  // Приложение ещё не выпущено, поэтому старое dev-состояние не мигрируем.
  // Записи той схемы читаются без ошибки: лишний ключ readOn просто
  // игнорируется, поэтому версия ключа не растёт.
  static const _key = 'course_progress_v4';

  int _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return 1;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return normalizeCourseTopic(json['topic'] as int? ?? 1);
  }

  Future<void> _write(int topic) => requirePreferenceWrite(
    _prefs.setString(_key, jsonEncode({'topic': topic})),
  );

  @override
  Future<Result<int>> currentTopic() => _guard(() async => _read());

  /// Записи выстраиваются в очередь, поэтому быстрые свайпы сохраняют тему
  /// в том же порядке, в котором юзер их видел.
  Future<Result<void>> _writing = Future.value(const Success(null));

  @override
  Future<Result<void>> saveCurrentTopic(int topic) =>
      _writing = _writing.then((_) => _guard(() => _write(topic)));

  Future<Result<T>> _guard<T>(Future<T> Function() op) async {
    try {
      return Success(await op());
    } on Object catch (e) {
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
