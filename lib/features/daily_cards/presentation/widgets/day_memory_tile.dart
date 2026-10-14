import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../../domain/entities/today_cards.dart';
import '../theme/card_type_style.dart';
import 'home_tile.dart';

/// Память дня на главной: такая же плитка, как «Мудрость дня», только
/// вместо декоративной иллюстрации справа икона праздника или святого.
///
/// Адрес иконы передаёт загрузчик содержимого дня. Если адреса нет,
/// название занимает плитку целиком.
class DayMemoryTile extends StatelessWidget {
  const DayMemoryTile({required this.day, this.iconUrl, this.onTap, super.key});

  final TodayCards day;
  final String? iconUrl;

  /// Открывает рассказ. Без ссылки на рассказ плитка не нажимается.
  final VoidCallback? onTap;

  /// Розовый свободен на главной: «Мудрость» янтарная, курс зелёный.
  static const _type = CardType.reading;

  static const _iconWidth = 100.0;
  static const _iconHeight = 132.0;

  /// Обычно икона целиком внутри плитки. Длинному названию она уступает
  /// место и чуть заходит за правый край, как иллюстрации соседних плиток.
  static const _iconRightInside = 16.0;
  static const _iconRightBleed = -6.0;

  static const _titleSize = 22.0;
  static const _titleLines = 3;

  /// Зазор между названием и иконой.
  static const _iconGap = 8.0;

  /// Сколько иконы прячется за нижним краем плитки.
  static const _iconBleed = 24.0;

  static const _placeholder = ColoredBox(color: Color(0x14000000));

  @override
  Widget build(BuildContext context) {
    final storyUrl = day.storyUrl;
    final title = day.title!.trim();
    final style = _type.styleFor(Theme.of(context).brightness);
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconRight =
            iconUrl == null ||
                _fitsBesideIcon(context, title, constraints.maxWidth)
            ? _iconRightInside
            : _iconRightBleed;
        return _tile(title, style, storyUrl, iconUrl, iconRight);
      },
    );
  }

  /// Помещается ли название в [_titleLines] строки рядом с иконой, которая
  /// стоит целиком внутри плитки. [width] — ширина вместе с полями экрана.
  bool _fitsBesideIcon(BuildContext context, String title, double width) {
    final tileWidth = width - AppSpacing.of(context).horizontal.horizontal;
    final textWidth = tileWidth - 20 - _iconRightInside - _iconWidth - _iconGap;
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: AppTheme.quoteStyle(
          context,
        ).copyWith(fontSize: _titleSize, height: 1.15),
      ),
      maxLines: _titleLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: textWidth);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  Widget _tile(
    String title,
    CardTypeStyle style,
    String? storyUrl,
    String? iconUrl,
    double iconRight,
  ) {
    return HomeTile(
      title: title,
      type: _type,
      titleFontSize: _titleSize,
      titleMaxLines: _titleLines,
      semanticsLabel: 'Память дня${day.isFast ? ', постный день' : ''}: $title',
      onTap: storyUrl == null ? null : onTap,
      // Подписи «Память дня» нет: название и икона говорят сами за себя.
      // Скринридеру тот же смысл даёт [semanticsLabel].
      status: day.isFast
          ? Text(
              'Постный день',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Строка статуса плитки высотой 14: кегль и интерлиньяж
              // подобраны так, чтобы надпись в неё помещалась.
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                color: style.tagForeground.withValues(alpha: 0.75),
              ),
            )
          : null,
      titleMaxWidth: null,
      illustration: iconUrl == null ? null : (_) => _icon(iconUrl),
      // Икона стоит, как иллюстрации соседних плиток: у правого нижнего угла
      // и уходит за нижний край. Текст освобождает ей место справа.
      illustrationOffset: Offset(iconRight, -_iconBleed),
      contentEndInset: iconUrl == null ? 20 : iconRight + _iconWidth + _iconGap,
    );
  }

  Widget _icon(String url) => DecoratedBox(
    // Лёгкая тень отделяет доску иконы от розового фона.
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _iconWidth,
        height: _iconHeight,
        // Икону обрезаем по рамке сверху: лик и главное в верхней части.
        child: Image.network(
          url,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          excludeFromSemantics: true,
          // Пока икона грузится или если не загрузилась, под тенью не
          // должно быть пустоты: держим спокойную подложку.
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _placeholder,
          errorBuilder: (context, error, stackTrace) => _placeholder,
        ),
      ),
    ),
  );
}
