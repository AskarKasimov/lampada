import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Заголовок раздела главной, например «Планы» над тем, что не привязано к
/// дню. Набран Lora, как названия карточек, но крупнее.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({required this.title, super.key});

  final String title;

  /// Кегль названия раздела и «Сегодня» в шапке: заметно крупнее названий
  /// карточек ниже.
  static const titleSize = 26.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding:
        AppSpacing.of(context).horizontal +
        const EdgeInsets.only(top: 28, bottom: 6),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: AppTheme.headingStyle(context, fontSize: titleSize),
      ),
    ),
  );
}
