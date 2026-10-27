import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Заголовок раздела главной: дата над тем, что меняется каждый день, и
/// «Планы» над тем, что не привязано к дню. Набран Lora, как названия
/// карточек, но крупнее; необязательная подпись под ним шрифтом интерфейса.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    this.caption,
    this.first = false,
    super.key,
  });

  final String title;

  /// Подпись под названием, например «Постный день».
  final String? caption;

  /// Первый раздел стоит сразу под шапкой; следующие отделены воздухом.
  final bool first;

  /// Кегль названия раздела: заметно крупнее названий карточек ниже.
  static const titleSize = 26.0;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          EdgeInsets.only(top: first ? 4 : 28, bottom: 6),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.headingStyle(context, fontSize: titleSize),
            ),
            if (caption != null)
              Text(
                caption,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  color: AppColorsExtension.of(context).textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
