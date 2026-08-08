import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Название курса «Основы» — одно на все входы в него.
const basicsCourseTitle = 'Основы веры';

/// Диаметр метки непрочитанного.
const _dotSize = 5.0;

/// Отступ слева под метку: строки выключены по одной линии, метка стоит на
/// поле — иначе прочитанный и непрочитанный вход были бы сдвинуты друг
/// относительно друга.
const _dotGutter = 13.0;

/// Одна запись дня на «Сегодня»: подпись разрядкой и текст антиквой.
///
/// Без рамки. Пять обведённых прямоугольников подряд читались таблицей
/// настроек, а материал приложения — бумага и антиква: группы разделяет
/// воздух и волосяная линия, иерархию задаёт кегль.
///
/// Метка ставится у НЕПРОЧИТАННОГО, а не у прочитанного. Гасить прочитанное
/// серым — читать задом наперёд: в приложении про копилку смыслов взятое
/// не становится менее важным. К вечеру метки гаснут, и страница остаётся
/// без единого элемента интерфейса.
class DayEntryRow extends StatelessWidget {
  const DayEntryRow({
    required this.label,
    required this.text,
    required this.isUnread,
    required this.onTap,
    super.key,
    this.labelColor,
    this.textSize = 16,
    this.maxLines = 2,
    this.showReadStatus = true,
  });

  /// Подпись разрядкой: «ЦИТАТА», «ЕВАНГЕЛИЕ ДНЯ», «ОСНОВЫ ВЕРЫ · 47».
  final String label;
  final String text;
  final bool isUnread;
  final VoidCallback onTap;

  /// Акцент типа. null — приглушённая подпись.
  final Color? labelColor;
  final double textSize;
  final int maxLines;
  final bool showReadStatus;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    return Semantics(
      button: true,
      label: '$label. $text${isUnread ? '' : '. Прочитано'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // Вертикальные 12 держат тап-таргет выше минимальных 44pt даже у
          // самой короткой строки.
          padding: const EdgeInsets.fromLTRB(_dotGutter, 12, 0, 12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      letterSpacing: 1.1,
                      color: labelColor ?? colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.quoteStyle(
                      context,
                    ).copyWith(fontSize: textSize, height: 1.35),
                  ),
                ],
              ),
              if (showReadStatus && isUnread)
                Positioned(
                  left: -_dotGutter,
                  top: 4,
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Волосяная линия между группами записей. Единственный разделитель на
/// экране: границ у самих записей нет.
class DayEntryDivider extends StatelessWidget {
  const DayEntryDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Container(
      height: 1,
      color: AppColorsExtension.of(context).chipUnreadBorder,
    ),
  );
}
