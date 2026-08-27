import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../format/app_download_links.dart';
import '../theme/app_colors.dart';

/// Отправляет текущий материал через системный лист ОС.
class AppShareButton extends StatelessWidget {
  const AppShareButton({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Builder(
      builder: (buttonContext) => IconButton(
        tooltip: 'Поделиться',
        onPressed: () => shareText(buttonContext, text),
        icon: Icon(CupertinoIcons.share, size: 22, color: colors.homeSubtitle),
      ),
    );
  }
}

/// Открывает системный лист отправки и на iPad привязывает его к кнопке.
Future<void> shareText(BuildContext context, String text) async {
  if (text.isEmpty) return;
  final box = context.findRenderObject()! as RenderBox;
  final origin = box.localToGlobal(Offset.zero) & box.size;
  await SharePlus.instance.share(
    ShareParams(
      text: appendAppDownloadLinks(text),
      sharePositionOrigin: origin,
    ),
  );
}
