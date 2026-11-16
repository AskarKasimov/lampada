import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../day_story/domain/entities/day_story.dart';
import '../../../day_story/presentation/providers/providers.dart';
import '../../../reading/domain/entities/daily_reading.dart';
import '../../../reading/presentation/providers/providers.dart';
import '../../domain/current_memory.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/day_memory.dart';
import '../../domain/entities/today_cards.dart';
import 'providers.dart';

/// Состояние содержимого дня. Ошибки и ожидание связанных материалов
/// независимы: недоступное Евангелие или рассказ не скрывают карточки.
class DayContentState {
  const DayContentState({
    required this.cards,
    this.reading,
    this.memory,
    this.story,
  });

  final AsyncValue<TodayCards> cards;
  final AsyncValue<DailyReading>? reading;

  /// Святой, которого показывает «Память дня», и прочитан ли он.
  final ({DayMemory memory, bool isRead})? memory;

  /// Рассказ о [memory].
  final AsyncValue<DayStory>? story;

  bool get readingIsLoading => reading?.isLoading ?? false;
  String? get iconUrl => story?.value?.iconUrl;
}

/// Единственная точка загрузки содержимого дня для главной и предзагрузки.
/// Семейства по ссылке переиспользуют чтение и рассказ даже между датами.
final dayContentProvider = Provider.family<DayContentState, String>((ref, key) {
  final cards = ref.watch(dayCardsProvider(key));
  final day = cards.value;
  final reference = day?.cards
      .where((card) => card.type == CardType.reading)
      .firstOrNull
      ?.reference;
  final readUrls =
      ref.watch(storyProgressProvider).value?.readOn(DateTime.parse(key)) ??
      const <String>{};
  final memories = day?.memories ?? const <DayMemory>[];
  final memory = currentMemory(memories, readUrls);
  // Следующего непрочитанного святого грузим заранее: вернувшись из
  // рассказа, юзер сразу видит на плитке его икону, а не имя.
  final upcoming = memory == null || memory.isRead
      ? null
      : memories
            .skip(memories.indexOf(memory.memory) + 1)
            .where((m) => !readUrls.contains(m.storyUrl))
            .firstOrNull;
  if (upcoming != null) ref.watch(dayStoryProvider(upcoming.storyUrl));
  return DayContentState(
    cards: cards,
    reading: reference == null
        ? null
        : ref.watch(dailyReadingProvider(reference)),
    memory: memory,
    story: memory == null
        ? null
        : ref.watch(dayStoryProvider(memory.memory.storyUrl)),
  );
});
