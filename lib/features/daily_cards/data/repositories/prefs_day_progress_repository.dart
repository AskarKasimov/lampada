import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result/result.dart';
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

  String get _today {
    final d = _clock();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DayProgressDto _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      return DayProgressDto(
        date: _today,
        readTypes: const [],
        streakDays: 0,
        lastCompleted: '',
      );
    }
    return DayProgressDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _write(DayProgressDto dto) =>
      _prefs.setString(_key, jsonEncode(dto.toJson()));

  /// Приводит DTO к сегодняшнему дню: если дата не сегодня —
  /// список прочитанного обнуляется, серия сохраняется.
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
      final updated = dto.copyWith(
        readTypes: {...dto.readTypes, type.name}.toList(),
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

  @override
  Future<Result<DayProgress>> completeDay() async {
    try {
      var dto = _forToday(_read());
      if (dto.lastCompleted != _today) {
        dto = dto.copyWith(
          streakDays: dto.streakDays + 1,
          lastCompleted: _today,
        );
      }
      await _write(dto);
      return Success(dto.toEntity());
    } on Exception catch (e) {
      return Failure(
        AppFailure(
          'Не удалось обновить серию',
          kind: FailureKind.unknown,
          cause: e,
        ),
      );
    }
  }
}
