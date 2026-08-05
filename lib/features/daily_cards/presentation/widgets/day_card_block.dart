import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

/// Блок дня в списке на «Сегодня»: тип, начало текста и отметка прочитанного.
///
/// Список блоков заменил экран завершения с кнопкой «Пройти снова»: день —
/// это набор его частей, к любой из которых можно вернуться, а не линия
/// с концом.
class DayCardBlock extends StatelessWidget {
  const DayCardBlock({
    super.key,
    required this.card,
    required this.isRead,
    required this.onTap,
  });

  final DayCard card;
  final bool isRead;
  final VoidCallback onTap;

  /// Превью в две строки. Карточка чтения текста не несёт — там лежит
  /// ссылка отрывка, поэтому подписываем её приглашением.
  String get _preview => card.type == CardType.reading
      ? 'Евангелие дня, ${card.body} — по одному стиху'
      : card.body.replaceAll('\n', ' ');

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final style = card.type.styleFor(Theme.of(context).brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.chipUnreadBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppPillBadge(
                    label: style.label,
                    background: style.tagBackground,
                    foreground: style.tagForeground,
                    letterSpacing: 0.2,
                  ),
                  const Spacer(),
                  // Прочитанное помечаем тихой галочкой, а не вычёркиванием:
                  // это не список дел, к блоку можно вернуться.
                  Icon(
                    isRead ? Icons.check_circle : Icons.circle_outlined,
                    size: 17,
                    color: isRead ? style.accent : colors.chipUnreadBorder,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isRead ? colors.textSecondary : colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
