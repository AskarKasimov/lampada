import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Строка-переход в Профиле: подпись слева, стрелка вовне справа.
///
/// Стрелка «вовне» (`arrow_outward`), а не шеврон «вглубь» (`chevron_right`):
/// все четыре действия здесь покидают приложение — браузер, системный лист
/// «поделиться», StoreKit, — а не открывают следующий экран внутри него.
class ProfileLinkTile extends StatelessWidget {
  const ProfileLinkTile({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, color: colors.ink),
                ),
              ),
              Icon(
                CupertinoIcons.arrow_up_right,
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
