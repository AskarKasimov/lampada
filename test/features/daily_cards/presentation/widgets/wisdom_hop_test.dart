import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/wisdom_hop.dart';

void main() {
  group('HopMotion', () {
    const motion = HopMotion();

    test('взлетает на заданную высоту и не уходит под землю', () {
      var peak = 0.0;
      for (var t = 0.0; t <= motion.duration; t += 0.002) {
        final lift = motion.at(t).lift;
        expect(lift, greaterThanOrEqualTo(0));
        if (lift > peak) peak = lift;
      }
      expect(peak, closeTo(motion.height, 0.5));
    });

    test('каждый отскок ниже предыдущего на квадрат упругости', () {
      final peaks = <double>[];
      var rising = true;
      var previous = 0.0;
      for (var t = 0.0; t <= motion.duration; t += 0.001) {
        final lift = motion.at(t).lift;
        if (rising && lift < previous) peaks.add(previous);
        rising = lift >= previous;
        previous = lift;
      }
      expect(peaks.length, greaterThanOrEqualTo(2));
      final ratio = motion.restitution * motion.restitution;
      expect(peaks[1] / peaks[0], closeTo(ratio, 0.05));
    });

    test(
      'при толчке и приземлении плитка сплющивается, потом успокаивается',
      () {
        expect(motion.at(0.02).squash, greaterThan(0.01));
        final landing = motion.firstLanding;
        expect(motion.at(landing + 0.02).squash, greaterThan(0.01));
        final end = motion.at(motion.duration);
        expect(end.lift, 0);
        expect(end.squash.abs(), lessThan(0.002));
      },
    );
  });

  group('WisdomHop', () {
    Widget app({required bool active, bool reduceMotion = false}) =>
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Center(
              child: WisdomHop(
                active: active,
                child: const SizedBox.square(dimension: 100),
              ),
            ),
          ),
        );

    double liftNow(WidgetTester tester) => -tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(WisdomHop),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .getTranslation()
        .y;

    /// Высоту собираем покадрово по ходу прыжка.
    Future<double> maxLift(WidgetTester tester, Duration span) async {
      var best = 0.0;
      for (var i = 0; i < span.inMilliseconds ~/ 16; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final lift = liftNow(tester);
        if (lift > best) best = lift;
      }
      return best;
    }

    testWidgets('активная плитка подпрыгивает и возвращается на место', (
      tester,
    ) async {
      await tester.pumpWidget(app(active: true));
      final best = await maxLift(tester, const Duration(seconds: 2));
      expect(best, greaterThan(8));
      await tester.pumpAndSettle();
      expect(liftNow(tester), 0);
    });

    testWidgets('неактивная плитка стоит на месте', (tester) async {
      await tester.pumpWidget(app(active: false));
      expect(await maxLift(tester, const Duration(seconds: 2)), 0);
    });

    testWidgets('«Уменьшение движения» отменяет прыжок', (tester) async {
      await tester.pumpWidget(app(active: true, reduceMotion: true));
      expect(await maxLift(tester, const Duration(seconds: 2)), 0);
    });

    testWidgets('выключение посреди прыжка сразу ставит плитку на место', (
      tester,
    ) async {
      await tester.pumpWidget(app(active: true));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpWidget(app(active: false));
      await tester.pump();
      expect(liftNow(tester), 0);
    });
  });
}
