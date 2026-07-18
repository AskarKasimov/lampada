// lib/features/daily_cards/presentation/widgets/home_button.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Круглая кнопка «на главный экран» в левом верхнем углу карточек и done.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.05),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.home_outlined, size: 20, color: AppColors.homeIcon),
        ),
      ),
    );
  }
}
