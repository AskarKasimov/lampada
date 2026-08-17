import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/course_calendar.dart';
import '../../domain/repositories/course_progress_repository.dart';

/// Прогресс курса в shared_preferences: номер текущей темы.
///
/// Ограничения «не больше темы в день» нет: сколько тем прочитать за раз,
/// решает юзер, и открыть следующую сразу после предыдущей — нормальный
/// сценарий, а не обход правила. Поэтому день последнего сдвига не хранится.
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

  Future<void> _write(int topic) =>
      requirePreferenceWrite(_prefs.setString(_key, jsonEncode({'topic': topic})));

  @override
  Future<Result<int>> currentTopic() => _guard(() async => _read());

  /// Операция продвижения в процессе — конкурентный вызов дожидается ЕЁ,
  /// а не запускает свою.
  ///
  /// Раньше отметка «Основы прочитаны» звалась из двух мест на одно открытие
  /// курса, и оба вызова доходили до продвижения почти одновременно: тема
  /// перескакивала на две вперёд за одно открытие («с 1-й на 3-ю»). Дубликат
  /// убран, но дедупликация оставлена: без дневного гарда она единственное,
  /// что защищает от быстрого повторного тапа, который успел бы прочитать
  /// номер темы до того, как первый вызов его записал.
  ///
  /// Работает, пока конкурентные вызовы идут через ОДИН инстанс — так и есть,
  /// `courseProgressRepositoryProvider` не `.family` и не `autoDispose`.
  Future<Result<void>>? _advancing;

  @override
  Future<Result<void>> markCurrentTopicRead() =>
      _advancing ??= _guard(() async {
        await _write(normalizeCourseTopic(_read() + 1));
      }).whenComplete(() => _advancing = null);

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
