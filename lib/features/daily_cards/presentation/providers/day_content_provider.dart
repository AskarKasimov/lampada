import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../day_story/domain/entities/day_story.dart';
import '../../../day_story/presentation/providers/providers.dart';
import '../../../reading/domain/entities/daily_reading.dart';
import '../../../reading/presentation/providers/providers.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/today_cards.dart';
import 'providers.dart';

/// Состояние содержимого дня. Ошибки и ожидание связанных материалов
/// независимы: недоступное Евангелие или рассказ не скрывают карточки.
class DayContentState {
  const DayContentState({required this.cards, this.reading, this.story});

  final AsyncValue<TodayCards> cards;
  final AsyncValue<DailyReading>? reading;
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
  final storyUrl = day?.storyUrl;
  return DayContentState(
    cards: cards,
    reading: reference == null
        ? null
        : ref.watch(dailyReadingProvider(reference)),
    story: storyUrl == null ? null : ref.watch(dayStoryProvider(storyUrl)),
  );
});
