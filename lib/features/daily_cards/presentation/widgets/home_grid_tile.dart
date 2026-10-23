import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

/// Плитка дня в ряду из двух на главной: иллюстрация на всю плитку и
/// небольшое название внизу на полосе матового стекла от края до края.
/// Стекло держит название читаемым поверх иконы и всё же даёт её видеть.
class HomeGridTile extends StatelessWidget {
  const HomeGridTile({
    required this.title,
    required this.type,
    required this.semanticsLabel,
    required this.onTap,
    required this.background,
    this.titleTrailing,
    super.key,
  });

  final String title;

  /// Цвета плитки берутся из стиля этого типа карточки.
  final CardType type;

  /// Иллюстрация под названием во всю плитку.
  final Widget Function(CardTypeStyle style) background;

  /// Отметка прочтения или индикатор загрузки справа от названия.
  final Widget? titleTrailing;

  final String semanticsLabel;

  /// `null` выключает нажатие, например пока материалы дня грузятся.
  final VoidCallback? onTap;

  /// В половину ширины телефона плитка почти квадратная: иллюстрации нужно
  /// место. Крупный текст может сделать её выше.
  static const minHeight = 176.0;

  static const _radius = 24.0;

  /// Матовость стекла под названием: формы под ним угадываются, детали
  /// размыты, как у стекла «glossiness 0.8» из референса.
  static const _frostBlur = 10.0;
  static const _frostTint = 0.5;

  @override
  Widget build(BuildContext context) {
    final style = type.styleFor(Theme.of(context).brightness);
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: ColoredBox(
          color: style.tagBackground,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: minHeight,
            ),
            // Всё нужное скринридеру уже в подписи плитки.
            child: ExcludeSemantics(
              child: Stack(
                // Название прижато к низу; высоту плитки задаёт минимум или
                // ряд, а при крупном тексте само название.
                alignment: AlignmentDirectional.bottomStart,
                children: [
                  Positioned.fill(child: background(style)),
                  SizedBox(
                    width: double.infinity,
                    child: _label(context, style),
                  ),
                  // Нажатие поверх иллюстрации: иначе волна от тапа
                  // пряталась бы под иконой.
                  Positioned.fill(
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(onTap: onTap),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, CardTypeStyle style) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _frostBlur, sigmaY: _frostBlur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.tagBackground.withValues(alpha: _frostTint),
            // Светлая кромка сверху: по ней полоса читается как стекло, а не
            // как заливка.
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.45),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
            // Отметка всегда справа, а не на новой строке под названием.
            child: Row(
              children: [
                Expanded(
                  // Название всегда в одну строку: если половины ширины
                  // мало, оно чуть уменьшается, а не переносится. Цвет
                  // текста как у заголовка «Сегодня», а не цвет плитки.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTheme.cardTitleStyle(context),
                    ),
                  ),
                ),
                if (titleTrailing case final trailing?) ...[
                  const SizedBox(width: 6),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
