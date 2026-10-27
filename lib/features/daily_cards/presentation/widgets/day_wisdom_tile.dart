import 'package:flutter/material.dart';

import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';
import 'home_grid_tile.dart';
import 'orthodox_cross.dart';
import 'read_status_checks.dart';

/// Крупный вход в дневные материалы с отметкой их общего прочтения. Фоном
/// служит «Картина дня» Азбуки; без неё, и пока она не загрузилась или если
/// не загрузилась, плитку держит нарисованный крест.
class DayWisdomTile extends StatelessWidget {
  const DayWisdomTile({
    required this.isUnread,
    required this.onTap,
    this.isLoading = false,
    this.pictureUrl,
    super.key,
  });

  final bool isUnread;
  final bool isLoading;
  final VoidCallback onTap;

  /// Адрес «Картины дня».
  final String? pictureUrl;

  /// Крест почти во всю плитку, как икона у соседней памяти дня. Он чуть
  /// уходит за нижний край, но верх и подножие остаются видны.
  static const _crossSize = 170.0;
  static const _crossOffset = Offset(-14, -18);

  @override
  Widget build(BuildContext context) => HomeGridTile(
    title: 'Мудрость дня',
    type: CardType.quote,
    background: (style) => switch (pictureUrl) {
      final url? => Image.network(
        url,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        // Пока картина грузится, видна спокойная заливка плитки: крест не
        // мелькает перед ней.
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const SizedBox.shrink(),
        errorBuilder: (context, error, stackTrace) => _cross(style),
      ),
      null => _cross(style),
    },
    semanticsLabel: isLoading
        ? 'Мудрость дня. Загружаем материалы дня'
        : 'Мудрость дня${isUnread ? '' : '. Прочитано'}',
    onTap: isLoading ? null : onTap,
    titleTrailing: isLoading
        ? const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : ReadStatusChecks(isUnread: isUnread),
  );

  Widget _cross(CardTypeStyle style) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        right: _crossOffset.dx,
        bottom: _crossOffset.dy,
        child: OrthodoxCross(
          color: style.accent.withValues(alpha: 0.28),
          size: _crossSize,
        ),
      ),
    ],
  );
}
