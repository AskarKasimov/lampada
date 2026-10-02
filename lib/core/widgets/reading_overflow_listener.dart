import 'package:flutter/material.dart';

/// Передаёт результат раскладки карточки её внешней панели действий.
/// У страницы и панели один источник решения о раскрытии полного текста.
class ReadingOverflowListener extends StatefulWidget {
  const ReadingOverflowListener({
    required this.onChanged,
    required this.child,
    super.key,
  });

  final ValueChanged<bool> onChanged;
  final Widget child;

  static void report(BuildContext context, bool needsFullText) {
    context.findAncestorStateOfType<_ReadingOverflowListenerState>()?._report(
      needsFullText,
    );
  }

  @override
  State<ReadingOverflowListener> createState() =>
      _ReadingOverflowListenerState();
}

class _ReadingOverflowListenerState extends State<ReadingOverflowListener> {
  bool? _lastValue;

  void _report(bool value) {
    if (_lastValue == value) return;
    _lastValue = value;
    // LayoutBuilder вызывается в layout-фазе; панель перестраивается после неё.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(_lastValue!);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
