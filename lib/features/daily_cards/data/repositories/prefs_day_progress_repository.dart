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

  /// Приводит DTO к сегодняшнему дню и переносит старое одиночное поле
  /// [DayProgressDto.readTypes] в историю. Старые версии не знают о карте,
  /// но новые продолжают читать их JSON без потери прогресса.
  DayProgressDto _forToday(DayProgressDto dto) {
    final history = {...dto.readTypesByDate};
    final visited = {...dto.visitedDays};
    if (dto.readTypes.isNotEmpty && !history.containsKey(dto.date)) {
      history[dto.date] = dto.readTypes;
      visited.add(dto.date);
    }
    return dto.copyWith(
      date: _today,
      readTypes: history[_today] ?? const [],
      readTypesByDate: history,
      visitedDays: visited.toList()..sort(),
    );
  }

  @override
  Future<Result<DayProgress>> loadToday() async {
    try {
      return Success(_forToday(_read()).toEntity());
    } on Object catch (e) {
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
  Future<Result<DayProgress>> markRead(
    CardType type, {
    DateTime? date,
    bool markVisited = true,
  }) async {
    try {
      final dto = _forToday(_read());
      final day = dateKey(date ?? _clock());
      final visited = {...dto.visitedDays, if (markVisited) day}.toList()
        ..sort();
      final retainedVisited = visited.length > _maxVisitedDays
          ? visited.sublist(visited.length - _maxVisitedDays)
          : visited;
      final readTypes = {
        ...dto.readTypesByDate[day] ?? const <String>[],
        type.name,
      }.toList();
      final byDate = {...dto.readTypesByDate, day: readTypes};
      final retainedReadDates = byDate.keys.toList()..sort();
      if (retainedReadDates.length > _maxVisitedDays) {
        for (final expired in retainedReadDates.take(
          retainedReadDates.length - _maxVisitedDays,
        )) {
          byDate.remove(expired);
        }
      }
      final updated = dto.copyWith(
        readTypes: day == _today ? readTypes : dto.readTypes,
        readTypesByDate: byDate,
        visitedDays: retainedVisited,
      );
      await _write(updated);
      return Success(updated.toEntity());
    } on Object catch (e) {
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
