import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_story.freezed.dart';

/// Рассказ о празднике или святом дня — то, что стоит за заголовком
/// на «Сегодня» («Мц. Христи́ны Тирской», «Светлое Христово Воскресение»).
///
/// Абзацы, а не готовый `body`: экран показывает их тем же приёмом, что
/// карточки дня, — единым текстом с переносами между абзацами.
@freezed
abstract class DayStory with _$DayStory {
  const factory DayStory({required List<String> paragraphs}) = _DayStory;
}
