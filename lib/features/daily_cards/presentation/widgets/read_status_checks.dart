import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Единая отметка прочтения материалов дня и личных планов.
class ReadStatusChecks extends StatelessWidget {
  const ReadStatusChecks({required this.isUnread, super.key});

  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ExcludeSemantics(
        child: SizedBox(
          width: 20,
          height: 14,
          child: Stack(
            children: [
              for (final left in [0.0, 5.0])
                Positioned(
                  left: left,
                  child: Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 14,
                    color: isUnread
                        ? colors.textTertiary.withValues(alpha: 0.4)
                        : colors.accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
