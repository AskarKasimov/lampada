import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Вход в личную копилку над настройками профиля.
class ProfileBookmarksTile extends StatelessWidget {
  const ProfileBookmarksTile({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              AppSpacing.of(context).horizontal +
              const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accent.withValues(alpha: 0.12),
                ),
                child: Icon(
                  CupertinoIcons.bookmark_fill,
                  size: 28,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Закладки',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: colors.homeSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
