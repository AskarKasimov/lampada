import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/day_card.dart';
import '../widgets/card_content.dart';

/// Полный текст одной карточки: здесь вертикальный жест прокручивает только
/// материал, а не переключает страницы основной читалки.
class FullCardTextScreen extends StatelessWidget {
  const FullCardTextScreen({required this.card, super.key});

  final DayCard card;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 56, 34, 24),
              child: CardContent(card: card, showBadge: false),
            ),
            Positioned(
              top: 0,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  CupertinoIcons.xmark,
                  size: 22,
                  color: colors.homeSubtitle,
                ),
                tooltip: 'Закрыть полный текст',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
