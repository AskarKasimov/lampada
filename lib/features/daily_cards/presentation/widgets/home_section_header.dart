import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Заголовок раздела главной: дата над тем, что меняется каждый день, и
/// «Планы» над тем, что не привязано к дню. Набран Lora, как названия
/// карточек, но крупнее; необязательная подпись шрифтом интерфейса стоит
/// справа в той же строке, чтобы не добавлять разделу высоты.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    this.caption,
    this.first = false,
    super.key,
  });

  final String title;

  /// Подпись справа от названия, например «Постный день».
  final String? caption;

  /// Первый раздел стоит сразу под шапкой; следующие отделены воздухом.
  final bool first;

  /// Кегль названия раздела: заметно крупнее названий карточек ниже.
  static const titleSize = 26.0;

  /// Минимальный зазор между названием и подписью в одной строке.
  static const _captionGap = 12.0;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    final titleStyle = AppTheme.headingStyle(context, fontSize: titleSize);
    final titleText = Text(title, style: titleStyle);
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          EdgeInsets.only(top: first ? 4 : 28, bottom: 6),
      child: Semantics(
        header: true,
        child: caption == null
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: titleText,
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final captionStyle = TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: AppColorsExtension.of(context).textSecondary,
                  );
                  final captionText = Text(caption, style: captionStyle);
                  final fits =
                      _lineWidth(context, title, titleStyle) +
                          _captionGap +
                          _lineWidth(context, caption, captionStyle) <=
                      constraints.maxWidth;
                  // При крупном шрифте строка не вмещает обоих: подпись
                  // уходит под название, а не обрезается.
                  if (!fits) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [titleText, captionText],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [titleText, captionText],
                  );
                },
              ),
      ),
    );
  }

  /// Ширина текста в одну строку с учётом масштаба шрифта, как его наберёт
  /// [Text] с тем же стилем.
  static double _lineWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
