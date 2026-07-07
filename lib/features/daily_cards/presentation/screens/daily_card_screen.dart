import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Ядро продукта: ОДНА карточка на весь экран.
/// «Дальше» — добровольно; после первой карточки сессия уже полноценна.
/// TODO: дизайн, анимация перехода, жесты, завершение сессии.
class DailyCardScreen extends ConsumerStatefulWidget {
  const DailyCardScreen({super.key});

  @override
  ConsumerState<DailyCardScreen> createState() => _DailyCardScreenState();
}

class _DailyCardScreenState extends ConsumerState<DailyCardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(todayCardsProvider);

    return Scaffold(
      body: SafeArea(
        child: cards.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // TODO: спокойный экран ошибки, не стектрейс.
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            final card = list[_index];
            final isLast = _index == list.length - 1;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(card.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(card.body,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Text(card.source,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 48),
                  if (!isLast)
                    FilledButton(
                      onPressed: () => setState(() => _index++),
                      child: const Text('Дальше'),
                    ),
                  // TODO: состояние «день пройден» на последней карточке.
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
