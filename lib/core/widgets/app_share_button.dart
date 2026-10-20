import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_provider.dart';
import '../format/app_download_links.dart';
import '../theme/app_colors.dart';

/// Отправляет текущий материал через системный лист ОС.
class AppShareButton extends ConsumerWidget {
  const AppShareButton({
    required this.text,
    required this.content,
    this.iconSize = 22,
    this.buttonSize,
    super.key,
  });

  final String text;

  /// Что отправляют: аналитика считает отправки по типу материала.
  final SharedContent content;
  final double iconSize;
  final double? buttonSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColorsExtension.of(context);
    return Builder(
      builder: (buttonContext) => IconButton(
        tooltip: 'Поделиться',
        onPressed: () async {
          final analytics = ref.read(analyticsProvider);
          final outcome = await shareText(buttonContext, text);
          if (outcome == null) return;
          analytics.log(
            AnalyticsEvent.contentShared(
              content: content,
              method: ShareMethod.button,
              result: outcome,
            ),
          );
        },
        constraints: buttonSize == null
            ? null
            : BoxConstraints.tightFor(width: buttonSize, height: buttonSize),
        padding: buttonSize == null ? null : EdgeInsets.zero,
        icon: Icon(
          CupertinoIcons.share,
          size: iconSize,
          color: colors.homeSubtitle,
        ),
      ),
    );
  }
}

/// Открывает системный лист отправки и на iPad привязывает его к кнопке.
/// Возвращает исход листа; null — отправлять было нечего.
Future<ShareOutcome?> shareText(BuildContext context, String text) async {
  if (text.isEmpty) return null;
  final box = context.findRenderObject()! as RenderBox;
  final origin = box.localToGlobal(Offset.zero) & box.size;
  final result = await SharePlus.instance.share(
    ShareParams(
      text: appendAppDownloadLinks(text),
      sharePositionOrigin: origin,
    ),
  );
  return shareOutcomeOf(result);
}

ShareOutcome shareOutcomeOf(ShareResult result) => switch (result.status) {
  ShareResultStatus.success => ShareOutcome.success,
  ShareResultStatus.dismissed => ShareOutcome.dismissed,
  ShareResultStatus.unavailable => ShareOutcome.unavailable,
};
