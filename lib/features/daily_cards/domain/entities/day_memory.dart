import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_memory.freezed.dart';

/// Память дня: святой, праздник или икона, о которых есть рассказ.
@freezed
abstract class DayMemory with _$DayMemory {
  const factory DayMemory({
    /// «Прп. Фомы́, иже в Мале́и».
    required String title,

    /// Страница рассказа. По ней же отмечается прочтение.
    required String storyUrl,
  }) = _DayMemory;
}
