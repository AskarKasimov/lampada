import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/repositories/wisdom_hint_repository.dart';

class PrefsWisdomHintRepository implements WisdomHintRepository {
  PrefsWisdomHintRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _openedKey = 'day_wisdom_opened';
  static const _sectionsKey = 'wisdom_sections_introduced';

  @override
  Future<Result<bool>> wisdomOpened() async {
    try {
      return Success(_prefs.getBool(_openedKey) ?? false);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать подсказку «Мудрости дня»',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markWisdomOpened() async {
    try {
      await requirePreferenceWrite(_prefs.setBool(_openedKey, true));
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить подсказку «Мудрости дня»',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Result<Set<CardType>> introducedSections() {
    try {
      final names = _prefs.getStringList(_sectionsKey) ?? const <String>[];
      return Success({
        for (final name in names)
          ?CardType.values.where((type) => type.name == name).firstOrNull,
      });
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось прочитать представленные разделы',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markSectionIntroduced(CardType type) async {
    try {
      final names = _prefs.getStringList(_sectionsKey) ?? const <String>[];
      if (names.contains(type.name)) return const Success(null);
      await requirePreferenceWrite(
        _prefs.setStringList(_sectionsKey, [...names, type.name]),
      );
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить представленный раздел',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
