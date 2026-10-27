import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Полноэкранный маршрут с общей длительностью нижнего модального перехода.
/// Material сохраняет платформенную траекторию, а длительность задаёт приложение.
class BottomUpModalRoute<T> extends MaterialPageRoute<T> {
  BottomUpModalRoute({required super.builder, super.settings})
    : super(fullscreenDialog: true);

  @override
  Duration get transitionDuration => AppMotion.modalEnter;

  @override
  Duration get reverseTransitionDuration => AppMotion.modalExit;
}
