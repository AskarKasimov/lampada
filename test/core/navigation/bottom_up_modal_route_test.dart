import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/navigation/bottom_up_modal_route.dart';
import 'package:lampada/core/theme/app_motion.dart';

void main() {
  test('uses shared modal entrance and exit durations', () {
    final route = BottomUpModalRoute<void>(builder: (_) => const SizedBox());

    expect(route.transitionDuration, AppMotion.modalEnter);
    expect(route.reverseTransitionDuration, AppMotion.modalExit);
    expect(route.fullscreenDialog, isTrue);
  });
}
