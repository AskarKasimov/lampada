import 'package:flutter/material.dart';

/// «Текущая серия N дней» — общий текст для Home и экрана завершения дня.
/// Тип отдельный, чтобы тесты читали [days] напрямую, а не парсили текст.
class StreakLabel extends StatelessWidget {
  const StreakLabel({super.key, required this.days, this.style});

  final int days;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text('Текущая серия $days дней', style: style);
  }
}
