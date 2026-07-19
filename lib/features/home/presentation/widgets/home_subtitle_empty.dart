import 'package:flutter/material.dart';

/// Подпись Home, когда за сегодня ещё ничего не прочитано.
class HomeSubtitleEmpty extends StatelessWidget {
  const HomeSubtitleEmpty({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text('Начните сессию', style: style);
}
