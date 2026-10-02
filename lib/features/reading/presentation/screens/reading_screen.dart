import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/brand_loading_view.dart';
import '../../../daily_cards/presentation/screens/card_viewer_screen.dart';
import '../providers/providers.dart';
import '../widgets/reading_card_pages.dart';

/// Загружает чтение дня и передаёт его стихи общему просмотрщику карточек.
/// После дневных стихов предлагает открыть полную главу с первого стиха.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({
    required this.reference,
    required this.date,
    required this.recordProgress,
    required this.recordRead,
    super.key,
  });

  final String reference;
  final DateTime date;
  final bool recordProgress;
  final bool recordRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyReadingProvider(reference));
    return async.when(
      loading: () => const Scaffold(body: BrandLoadingView()),
      error: (e, _) => Scaffold(
        body: SafeArea(
          child: _ErrorView(
            kind: switch (e) {
              AppFailure(kind: final k) => k,
              _ => FailureKind.unknown,
            },
            onRetry: () => ref.invalidate(dailyReadingProvider(reference)),
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      data: (reading) {
        final pages = ReadingCardPages(reference: reference, reading: reading);
        return CardViewerScreen(
          cards: pages.cards,
          startIndex: 0,
          date: date,
          recordProgress: recordProgress,
          recordRead: recordRead,
          actionsBuilder: pages.actions,
          pageBuilder: pages.page,
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.kind,
    required this.onRetry,
    required this.onClose,
  });

  final FailureKind kind;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final title = kind == FailureKind.network
        ? 'Нет подключения к интернету'
        : 'Чтение сейчас недоступно';

    return Center(
      child: Padding(
        padding: AppSpacing.of(context).horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Карточки дня остаются с вами',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.homeSubtitle),
            ),
            const SizedBox(height: 12),
            AppLinkButton(
              label: 'Повторить',
              color: colors.link,
              fontSize: 12,
              onPressed: onRetry,
            ),
            AppLinkButton(
              label: 'Вернуться к карточкам',
              color: colors.homeSubtitle,
              fontSize: 12,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
