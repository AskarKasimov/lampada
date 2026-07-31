import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/daily_reading.dart';

/// Один стих на весь экран — герой ридера (§6). Номер подписью снизу,
/// чтобы не разбивать сам текст служебной цифрой.
class VerseView extends StatelessWidget {
  const VerseView({super.key, required this.verse, this.onOpenInterpretation});

  final Verse verse;

  /// null — у стиха толкования нет, действие не показываем.
  final VoidCallback? onOpenInterpretation;

  /// Стихи бывают и в строку, и на добрый абзац — кегль подбираем по длине,
  /// иначе длинный стих не влезает и «один стих = один экран» ломается.
  static double _fontSizeFor(int length) {
    if (length <= 160) return 26;
    if (length <= 320) return 22;
    if (length <= 520) return 19;
    return 17;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            verse.text,
            textAlign: TextAlign.center,
            style: AppTheme.quoteStyle(context)
                .copyWith(fontSize: _fontSizeFor(verse.text.length), height: 1.5),
          ),
          const SizedBox(height: 18),
          Text(
            '${verse.chapter}:${verse.number}',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.4,
              color: colors.textSecondary,
            ),
          ),
          if (onOpenInterpretation != null) ...[
            const SizedBox(height: 22),
            VerseInterpretationButton(onPressed: onOpenInterpretation!),
          ],
        ],
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
  const VerseInterpretationButton({super.key, required this.onPressed});

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
              Icon(Icons.menu_book_outlined, size: 15, color: colors.accent),
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
