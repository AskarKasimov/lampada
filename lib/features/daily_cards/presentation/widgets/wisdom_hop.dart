import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Прыжок плитки как у мяча: толчок, свободный полёт под действием тяжести
/// и отскоки, каждый из которых теряет часть скорости. В момент толчка и
/// каждого приземления плитка пружинисто сплющивается и распрямляется.
///
/// Считается по времени, а не по кривой: высота следует законам падения,
/// поэтому наверху плитка замедляется, а у земли разгоняется.
class HopMotion {
  // Слабая тяжесть делает полёт долгим и плавным, малая упругость
  // оставляет после него один едва заметный отскок, а сильное затухание
  // пружины не даёт плитке дрожать, как желе.
  const HopMotion({
    this.height = 14,
    this.gravity = 420,
    this.restitution = 0.3,
    this.squashPerSpeed = 0.045 / 108,
    this.springHz = 5,
    this.springDamping = 0.7,
  });

  /// Высота первого прыжка, логические пиксели.
  final double height;

  /// Ускорение падения, пикселей в секунду за секунду.
  final double gravity;

  /// Доля скорости, которая остаётся после удара о землю.
  final double restitution;

  /// Сплющивание на каждый пиксель в секунду скорости удара.
  final double squashPerSpeed;

  /// Частота и затухание пружины, которая сплющивает плитку.
  final double springHz;
  final double springDamping;

  /// Ниже этой высоты отскок уже не виден и полёт заканчивается.
  static const _minPeak = 0.8;

  /// Сплющивание считаем успокоившимся, когда его огибающая меньше этого.
  static const _restSquash = 0.001;

  double get _launchSpeed => math.sqrt(2 * gravity * height);

  /// Скорости взлёта каждого отскока.
  List<double> get _speeds {
    final speeds = <double>[];
    for (var v = _launchSpeed; v * v / (2 * gravity) >= _minPeak;) {
      speeds.add(v);
      v *= restitution;
    }
    return speeds;
  }

  /// Моменты касания земли: толчок, затем приземления.
  List<double> get _contacts {
    final contacts = [0.0];
    for (final v in _speeds) {
      contacts.add(contacts.last + 2 * v / gravity);
    }
    return contacts;
  }

  double get _omega => 2 * math.pi * springHz;

  /// Когда плитка впервые возвращается на землю.
  double get firstLanding => _contacts[1];

  /// Полная длительность: полёт и затухание последнего сплющивания.
  double get duration {
    final lastImpact = _speeds.last * squashPerSpeed;
    final settle =
        math.log(lastImpact / _restSquash) / (springDamping * _omega);
    return _contacts.last + math.max(settle, 0);
  }

  /// Положение через [seconds] после толчка: [lift] вверх в пикселях,
  /// [squash] доля сжатия по высоте (меньше нуля — вытягивание).
  ({double lift, double squash}) at(double seconds) {
    final speeds = _speeds;
    final contacts = _contacts;
    var lift = 0.0;
    for (var i = 0; i < speeds.length; i++) {
      if (seconds >= contacts[i] && seconds < contacts[i + 1]) {
        final t = seconds - contacts[i];
        lift = math.max(0, speeds[i] * t - gravity * t * t / 2);
        break;
      }
    }

    // Каждое касание толкает пружину с силой, пропорциональной скорости:
    // толчок вверх и удар при приземлении. Затухающие колебания
    // складываются.
    final damped = _omega * math.sqrt(1 - springDamping * springDamping);
    var squash = 0.0;
    for (var i = 0; i < contacts.length; i++) {
      final t = seconds - contacts[i];
      if (t < 0) continue;
      final impact = i == 0 ? speeds.first : speeds[i - 1];
      squash +=
          impact *
          squashPerSpeed *
          math.exp(-springDamping * _omega * t) *
          math.sin(damped * t);
    }
    return (lift: lift, squash: squash);
  }
}

/// Плитка, которая несколько раз подпрыгивает, пока [active], зовя к себе.
///
/// Прыжки идут с паузами и затем прекращаются: подсказка не должна
/// превращаться в мигающую рекламу. «Уменьшение движения» её отключает.
class WisdomHop extends StatefulWidget {
  const WisdomHop({required this.active, required this.child, super.key});

  final bool active;
  final Widget child;

  @override
  State<WisdomHop> createState() => _WisdomHopState();
}

class _WisdomHopState extends State<WisdomHop>
    with SingleTickerProviderStateMixin {
  static const _motion = HopMotion();

  /// Пауза, чтобы главная успела показаться, и паузы между прыжками.
  static const _delay = 0.8;
  static const _pause = 2.0;
  static const _hops = 5;

  static double get _total =>
      _delay + _hops * _motion.duration + (_hops - 1) * _pause;

  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(microseconds: (_total * 1e6).round()),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void didUpdateWidget(WisdomHop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _start();
    if (!widget.active && oldWidget.active) _controller.reset();
  }

  void _start() {
    if (!mounted || !widget.active) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Положение прыжка в общей ленте с задержкой и паузами.
  ({double lift, double squash}) _pose() {
    if (!_controller.isAnimating) return (lift: 0, squash: 0);
    var t = _controller.value * _total - _delay;
    for (var i = 0; i < _hops; i++) {
      if (t < 0) break;
      if (t < _motion.duration) return _motion.at(t);
      t -= _motion.duration + _pause;
    }
    return (lift: 0, squash: 0);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final pose = _pose();
      // Сплющивание сохраняет объём: ниже по высоте — шире по ширине.
      return Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.translationValues(0, -pose.lift, 0)
          ..multiply(
            Matrix4.diagonal3Values(1 + pose.squash / 2, 1 - pose.squash, 1),
          ),
        child: child,
      );
    },
  );
}
