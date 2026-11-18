import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/date_key.dart';
import '../../../bible/presentation/providers/providers.dart';
import '../providers/day_content_provider.dart';

/// Грузит содержимое сегодняшнего дня с запуска приложения, а не с первого
/// показа главной: Евангелие, рассказ «Памяти дня» с иконой, «Стих дня» и
/// «Картину дня». Новичок между запуском и главной проходит приветствие, и
/// без этого на главной его ждали бы лоадеры.
///
/// Живёт над навигатором всё время работы приложения: подписка держит
/// провайдеры активными, иначе зависимые загрузки (Евангелие ждёт ссылку из
/// карточек) не начались бы, пока главной нет на экране.
class DayPreloader extends ConsumerStatefulWidget {
  const DayPreloader({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DayPreloader> createState() => _DayPreloaderState();
}

class _DayPreloaderState extends ConsumerState<DayPreloader> {
  final _precached = <String>{};

  /// Картинки плиток кладём в кэш изображений: главная покажет их сразу,
  /// без пустой плитки. Ошибка загрузки тут не важна, плитка обработает её
  /// сама.
  void _precacheImages(DayContentState content) {
    for (final url in [content.cards.value?.pictureUrl, content.iconUrl]) {
      if (url == null || !_precached.add(url)) continue;
      precacheImage(
        NetworkImage(url),
        context,
        onError: (error, stackTrace) => _precached.remove(url),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Ключ берём на запуске: смену дня и возврат из фона главная и
    // RefreshOnResume обрабатывают сами, а подписка лишь держит загрузку.
    final key = dateKey(DateTime.now());
    ref
      ..listenManual(
        dayContentProvider(key),
        // Картинкам нужен контекст с размерами экрана, а первый вызов
        // приходит ещё из initState.
        (_, content) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _precacheImages(content);
        }),
        fireImmediately: true,
      )
      ..listenManual(verseOfDayProvider(key), (_, _) {});
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
