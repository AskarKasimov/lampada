import 'package:flutter/widgets.dart';

/// Позволяет внешнему жесту закрытия уступить выделению текста.
class TextSelectionActivity extends Notification {
  const TextSelectionActivity({required this.active});

  final bool active;
}
