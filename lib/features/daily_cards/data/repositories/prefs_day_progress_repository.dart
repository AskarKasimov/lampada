import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/format/date_key.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/preference_write.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_progress.dart';
import '../../domain/repositories/day_progress_repository.dart';
import '../dto/day_progress_dto.dart';
import '../mappers/day_progress_mapper.dart';

/// Хранит прогресс дня одним JSON-значением в shared_preferences.
/// Единственное место, где исключения data-слоя превращаются в Failure.
class PrefsDayProgressRepository implements DayProgressRepository {
  PrefsDayProgressRepository(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const _key = 'day_progress';

  /// Сколько дней активности держим. Календарь листают на месяцы, не на годы,
  /// а prefs — не база: неограниченный список рос бы вечно.
  static const _maxVisitedDays = 400;

  String get _today => dateKey(_clock());

  DayProgressDto _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      return DayProgressDto(date: _today, readTypes: const []);
    }
    return DayProgressDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _write(DayProgressDto dto) =>
      requirePreferenceWrite(_prefs.setString(_key, jsonEncode(dto.toJson())));

  /// Приводит DTO к сегодняшнему дню: если дата не сегодня —
  /// список прочитанного обнуляется, посещённые дни сохраняются.
  DayProgressDto _forToday(DayProgressDto dto) => dto.date == _today
      ? dto
      : dto.copyWith(date: _today, readTypes: const []);

  @override
  Future<Result<DayProgress>> loadToday() async {
    try {
      return Success(_forToday(_read()).toEntity());
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось загрузить прогресс дня',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Result<DayProgress>> markRead(CardType type) async {
    try {
      final dto = _forToday(_read());
      final visited = {...dto.visitedDays, _today}.toList()..sort();
      final updated = dto.copyWith(
        readTypes: {...dto.readTypes, type.name}.toList(),
        visitedDays: visited.length > _maxVisitedDays
            ? visited.sublist(visited.length - _maxVisitedDays)
            : visited,
      );
      await _write(updated);
      return Success(updated.toEntity());
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось сохранить прогресс',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
