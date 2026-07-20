import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Круглая кнопка «на главный экран» в левом верхнем углу карточек и done.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Material(
      color: colors.homeButtonBackground,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.home_outlined,
            size: 20,
            color: colors.homeIcon,
          ),
        ),
      ),
    );
  }
}
