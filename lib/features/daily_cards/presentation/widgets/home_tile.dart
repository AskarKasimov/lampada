import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

/// Широкая цветная плитка входа на главной, например в курс.
///
/// Заголовок (при крупном тексте переносится) с отметкой прочтения справа,
/// необязательная мелкая подпись под ним и иллюстрация у правого нижнего
/// угла. Отметка в строке заголовка, а не отдельной строкой над ним: так
/// компактная плитка остаётся низкой, а заголовок стоит ровно посередине.
class HomeTile extends StatelessWidget {
  const HomeTile({
    required this.title,
    required this.type,
    required this.semanticsLabel,
    required this.onTap,
    this.illustration,
    this.titleTrailing,
    this.subtitle,
    this.minHeight = compactHeight,
    super.key,
  });

  final String title;

  /// Цвета плитки берутся из стиля этого типа карточки.
  final CardType type;

  /// Декоративная иллюстрация у правого нижнего угла; цвет задаёт плитка.
  final Widget Function(Color color)? illustration;

  /// Отметка прочтения или индикатор загрузки справа от заголовка.
  final Widget? titleTrailing;

  /// Мелкая подпись под заголовком, например «7/365».
  final String? subtitle;

  /// Нижняя граница высоты.
  final double minHeight;

  final String semanticsLabel;

  /// `null` выключает нажатие, например пока материалы дня грузятся.
  final VoidCallback? onTap;

  /// Правое поле под декоративную иллюстрацию (крест, книга).
  static const illustrationInset = 108.0;

  /// Высота компактной плитки: заголовок с подписью и поля. Декоративные
  /// иллюстрации подобраны под неё (см. [illustrationSize]).
  static const compactHeight = 84.0;

  /// Размер креста и книги в компактной плитке: крупнее самой плитки, как
  /// водяной знак. Они уходят за нижний край на 24 и чуть за правый, но
  /// верх креста и его подножие остаются внутри, и силуэт читается.
  static const illustrationSize = 112.0;
  static const _illustrationOffset = Offset(-8, -24);

  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final style = type.styleFor(Theme.of(context).brightness);
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        container: true,
        button: true,
        enabled: onTap != null,
        label: semanticsLabel,
        child: Material(
          color: style.tagBackground,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              // Плитка всегда во всю ширину, даже в Column без stretch.
              constraints: BoxConstraints(
                minWidth: double.infinity,
                minHeight: minHeight,
              ),
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (illustration case final illustration?)
                    Positioned(
                      right: _illustrationOffset.dx,
                      bottom: _illustrationOffset.dy,
                      child: ExcludeSemantics(
                        child: illustration(
                          style.accent.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                  // Всё нужное скринридеру уже в подписи плитки.
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        illustrationInset,
                        16,
                      ),
                      child: _content(context),
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

  Widget _content(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Цвета текста как у заголовка «Сегодня» и подписей главной.
          Text(title, style: AppTheme.cardTitleStyle(context)),
          ?titleTrailing,
        ],
      ),
      if (subtitle case final subtitle?) ...[
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.cardCaptionStyle(context),
        ),
      ],
    ],
  );
}
