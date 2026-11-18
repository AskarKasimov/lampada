import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/section_pill_intro.dart';

void main() {
  const motion = SectionIntroMotion();

  test('плашка проявляется на месте чуть крупнее обычного', () {
    final start = motion.at(0);
    expect(start.opacity, 0);
    expect(start.scale, greaterThan(1.3));

    final hold = motion.at(motion.returnStart - 0.05);
    expect(hold.opacity, 1);
    expect(hold.scale, closeTo(motion.bigScale, 0.01));
    expect(motion.bigScale, lessThanOrEqualTo(1.6));
  });

  test('садится в обычный размер пружиной без желейной дрожи', () {
    var smallest = double.infinity;
    for (var t = motion.returnStart; t <= motion.duration; t += 0.005) {
      final scale = motion.at(t).scale;
      if (scale < smallest) smallest = scale;
    }
    // Почти не проскакивает меньше обычного размера.
    expect(smallest, greaterThan(0.985));

    final end = motion.at(motion.duration);
    expect(end.scale, 1);
    expect(end.opacity, 1);
  });
}
