import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/repositories/story_hint_repository.dart';

class PrefsStoryHintRepository implements StoryHintRepository {
  PrefsStoryHintRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _contentsKey = 'story_contents_opened';

  @override
  Future<Result<bool>> contentsOpened() async {
    try {
      return Success(_prefs.getBool(_contentsKey) ?? false);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать подсказку рассказа',
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
          'Не удалось сохранить подсказку рассказа',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
