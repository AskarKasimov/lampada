import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/repositories/course_hint_repository.dart';

class PrefsCourseHintRepository implements CourseHintRepository {
  PrefsCourseHintRepository(this._prefs);

  final SharedPreferences _prefs;

  // Прежний ключ `course_contents_hint_shown` ставился уже при показе
  // пульсации. Новый ставит только нажатие, поэтому тем, кто подсказку
  // видел, но не нажал, она вернётся.
  static const _contentsKey = 'course_contents_opened';

  @override
  Future<Result<bool>> contentsOpened() async {
    try {
      return Success(_prefs.getBool(_contentsKey) ?? false);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать подсказку курса',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markContentsOpened() async {
    try {
      await requirePreferenceWrite(_prefs.setBool(_contentsKey, true));
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить подсказку курса',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
