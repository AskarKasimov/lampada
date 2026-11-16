import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/repositories/review_prompt_repository.dart';

/// Состояние запросов оценки в shared_preferences: два простых значения.
class PrefsReviewPromptRepository implements ReviewPromptRepository {
  PrefsReviewPromptRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _firstOpenKey = 'review_first_open_day';
  static const _requestedKey = 'review_requested';

  @override
  Future<Result<ReviewPromptState>> load() async {
    try {
      final names = ReviewMoment.values.asNameMap();
      return Success((
        firstOpenDay: _prefs.getString(_firstOpenKey),
        // Незнакомые значения могли записать будущие версии: пропускаем.
        requested: {
          for (final name
              in _prefs.getStringList(_requestedKey) ?? const <String>[])
            ?names[name],
        },
      ));
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать запросы оценки',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> save(ReviewPromptState state) async {
    try {
      final firstOpenDay = state.firstOpenDay;
      if (firstOpenDay != null) {
        await requirePreferenceWrite(
          _prefs.setString(_firstOpenKey, firstOpenDay),
        );
      }
      await requirePreferenceWrite(
        _prefs.setStringList(_requestedKey, [
          for (final moment in state.requested) moment.name,
        ]),
      );
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить запросы оценки',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
