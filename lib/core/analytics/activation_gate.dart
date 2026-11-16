/// Откладывает действия до открытия: события аналитики ждут активации SDK.
class ActivationGate {
  final _pending = <void Function()>[];
  bool _open = false;

  void run(void Function() action) {
    if (_open) {
      action();
    } else {
      _pending.add(action);
    }
  }

  void open() {
    if (_open) return;
    _open = true;
    for (final action in _pending) {
      action();
    }
    _pending.clear();
  }
}
