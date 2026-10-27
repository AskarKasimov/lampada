import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/repositories/day_wisdom_position_repository.dart';

/// Хранит один индекс вместе с датой, чтобы позиция не переносилась на завтра.
class PrefsDayWisdomPositionRepository implements DayWisdomPositionRepository {
  PrefsDayWisdomPositionRepository(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const _dateKey = 'day_wisdom_position_date';
  static const _pageKey = 'day_wisdom_position_page';

  @override
  Result<int?> load(DateTime date) {
    try {
      final today = dateKey(_clock());
      if (dateKey(date) != today || _prefs.getString(_dateKey) != today) {
        return const Success(null);
      }
      return Success(_prefs.getInt(_pageKey));
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось загрузить страницу «Мудрости дня»',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> save(DateTime date, int pageIndex) async {
    try {
      final today = dateKey(_clock());
      if (dateKey(date) != today || pageIndex < 0) return const Success(null);
      await requirePreferenceWrite(_prefs.setInt(_pageKey, pageIndex));
      await requirePreferenceWrite(_prefs.setString(_dateKey, today));
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить страницу «Мудрости дня»',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
