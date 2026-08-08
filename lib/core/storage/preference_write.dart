/// Превращает неподтверждённую платформой запись в исключение, которое
/// repository затем упакует в `AppFailure`.
Future<void> requirePreferenceWrite(Future<bool> operation) async {
  if (!await operation) {
    throw Exception('Платформа не подтвердила запись в SharedPreferences');
  }
}
