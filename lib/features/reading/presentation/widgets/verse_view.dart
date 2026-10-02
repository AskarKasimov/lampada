import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/reading_font_size.dart';
import '../../../../core/theme/reading_text_layout.dart';
import '../../../../core/widgets/reading_action_space.dart';
import '../../../../core/widgets/reading_overflow_listener.dart';
import '../../../../core/widgets/selectable_share_area.dart';
import '../../domain/entities/daily_reading.dart';

/// Один стих на весь экран — герой ридера (§6). Номер подписью снизу,
/// чтобы не разбивать сам текст служебной цифрой.
class VerseView extends StatelessWidget {
  const VerseView({required this.verse, super.key, this.onOpenInterpretation});

  final Verse verse;

  /// null — у стиха толкования нет, действие не показываем.
  final VoidCallback? onOpenInterpretation;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);

    final numberStyle = TextStyle(
      fontSize: 12,
      letterSpacing: 0.4,
      color: colors.textSecondary,
    );
    return SelectableShareArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight =
              constraints.maxHeight - ReadingActionSpace.of(context);
          final footerHeight =
              18 +
              readingTextHeight(
                context: context,
                text: '${verse.chapter}:${verse.number}',
                style: numberStyle,
                maxWidth: constraints.maxWidth,
              ) +
              (onOpenInterpretation != null ? 22 + 44 : 0);
          final baseStyle = AppTheme.readingTextStyle(context);
          final scaler = MediaQuery.textScalerOf(context);
          final scaledFooterHeight =
              18 +
              readingTextHeight(
                context: context,
                text: '${verse.chapter}:${verse.number}',
                style: numberStyle,
                maxWidth: constraints.maxWidth,
                textScaler: scaler,
              ) +
              (onOpenInterpretation != null
                  ? 22 +
                        (readingTextHeight(
                                  context: context,
                                  text: 'Толкование',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                  ),
                                  maxWidth: constraints.maxWidth - 54,
                                  textScaler: scaler,
                                ) +
                                18)
                            .clamp(44.0, double.infinity)
                  : 0);
          final layout = readingTextLayout(
            context: context,
            text: verse.text,
            style: baseStyle,
            maxWidth: constraints.maxWidth,
            maxHeight: availableHeight - footerHeight,
            scaledMaxHeight: availableHeight - scaledFooterHeight,
            previewExtraHeight: ReadingActionSpace.extraForPreview(context),
          );
          ReadingOverflowListener.report(context, layout.needsFullText);
          final text = layout.text;
          final bodyStyle = baseStyle.copyWith(fontSize: layout.fontSize);
          return SingleChildScrollView(
            child: SizedBox(
              height: constraints.maxHeight,
              child: ReadingContentPosition(
                needsFullText: layout.needsFullText,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(text, textAlign: TextAlign.center, style: bodyStyle),
                    const SizedBox(height: 18),
                    Text(
                      '${verse.chapter}:${verse.number}',
                      style: numberStyle,
                    ),
                    if (onOpenInterpretation != null) ...[
                      const SizedBox(height: 22),
                      VerseInterpretationButton(
                        onPressed: onOpenInterpretation!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// «Толкование» под стихом — свой тип, чтобы тесты искали по структуре,
/// а не по тексту кнопки.
///
/// Обведённая пилюля с иконкой, а не текстовая ссылка 12-м кеглем: ссылкой
/// действие терялось под номером стиха и его просто не находили. Контур, а не
/// заливка — по §6 высокий контраст остаётся за самим стихом.
class VerseInterpretationButton extends StatelessWidget {
  const VerseInterpretationButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          // 44pt — минимум по HIG. Material-кнопки держат его сами, а эта
          // собрана вручную и давала ~35pt.
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: BorderSide(color: colors.accent.withValues(alpha: 0.55)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.book, size: 15, color: colors.accent),
              const SizedBox(width: 7),
              Text(
                'Толкование',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.2,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
