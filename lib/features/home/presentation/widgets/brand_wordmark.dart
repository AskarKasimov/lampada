import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// «Лампада» с буквицей. Устав тут был бы анахронизмом — уставом писали
/// церковнославянские богослужебные тексты, а не русские названия. Церковность
/// синодальных изданий держится на инициалах и вёрстке при обычном гражданском
/// шрифте; это и повторяем.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final base = AppTheme.quoteStyle(context).copyWith(fontSize: 36);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Л',
            style: base.copyWith(fontSize: 52, color: colors.accent),
          ),
          TextSpan(text: 'ампада', style: base),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
