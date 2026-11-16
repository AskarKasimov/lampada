import 'entities/day_memory.dart';

/// Память, которую показывает плитка «Память дня»: первая непрочитанная из
/// [memories] по [readUrls]. Прочитав святого, юзер возвращается на главную
/// уже к следующему. Когда прочитаны все, плитка снова показывает первого,
/// с горящими галочками.
({DayMemory memory, bool isRead})? currentMemory(
  List<DayMemory> memories,
  Set<String> readUrls,
) {
  if (memories.isEmpty) return null;
  for (final memory in memories) {
    if (!readUrls.contains(memory.storyUrl)) {
      return (memory: memory, isRead: false);
    }
  }
  return (memory: memories.first, isRead: true);
}
