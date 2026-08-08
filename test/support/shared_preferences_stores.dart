import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void installSharedPreferencesStore(SharedPreferencesStorePlatform store) {
  SharedPreferencesStorePlatform.instance = store;
}

/// Платформа принимает вызов, но не подтверждает запись.
class RejectingWriteStore extends SharedPreferencesStorePlatform {
  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() async => {};

  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

/// Платформа аварийно завершает запись кэша.
class ThrowingWriteStore extends SharedPreferencesStorePlatform {
  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() async => {};

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      Future<bool>.error(Exception('диск недоступен'));
}
