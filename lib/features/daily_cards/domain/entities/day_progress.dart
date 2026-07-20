import 'package:freezed_annotation/freezed_annotation.dart';

import 'day_card.dart';

part 'day_progress.freezed.dart';

/// Прогресс дня: прочитанные сегодня типы карточек и длина серии
/// («Лампадка»). Domain-модель, без JSON.
@freezed
abstract class DayProgress with _$DayProgress {
  const DayProgress._();

  const factory DayProgress({
    required Set<CardType> readTypes,
    required int streakDays,
  }) = _DayProgress;

  bool isRead(CardType type) => readTypes.contains(type);

  bool get allRead => readTypes.length == CardType.values.length;

  int get readCount => readTypes.length;

  /// Первый непрочитанный тип в фиксированном порядке показа, либо null.
  CardType? get firstUnread {
    for (final type in CardType.values) {
      if (!readTypes.contains(type)) return type;
    }
    return null;
  }
}
