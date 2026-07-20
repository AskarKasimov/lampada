import 'package:flutter/material.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_link_button.dart';
import 'brand_mark.dart';

/// Home, когда карточек нет вообще: сеть не отвечает и кэш пуст (первый
/// запуск). Брендинг остаётся на месте — это состояние Home, а не отдельный
/// экран ошибки.
class HomeOfflineView extends StatelessWidget {
  const HomeOfflineView({
    super.key,
    required this.kind,
    required this.onRetry,
  });

  final FailureKind kind;
  final VoidCallback onRetry;

  /// Совет «включите Wi-Fi» уместен только при сетевом сбое: если лёг сам
  /// azbyka.ru, он отправит юзера чинить исправный интернет.
  ({String title, String hint}) get _copy => switch (kind) {
        FailureKind.network => (
            title: 'Нет подключения к интернету',
            hint: 'Включите Wi-Fi или мобильную сеть',
          ),
        FailureKind.server || FailureKind.unknown => (
            title: 'Азбука веры сейчас недоступна',
            hint: 'Попробуйте позже',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final copy = _copy;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(),
            const SizedBox(height: 24),
            Text(
              copy.title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              copy.hint,
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
          ],
        ),
      ),
    );
  }
}
