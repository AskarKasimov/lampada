import 'package:flutter/services.dart';

/// Ответ пользователя на запрос App Tracking Transparency. [unsupported]
/// — запроса нет вовсе: Android, iOS ниже 14 или тесты без нативной части.
enum TrackingStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  unsupported,
}

/// Запрос разрешения на трекинг (IDFA) через нативный канал AppDelegate.
/// Системное окно iOS показывает один раз за установку; дальше запрос сразу
/// возвращает сохранённый ответ.
class TrackingConsent {
  const TrackingConsent();

  static const _channel = MethodChannel('lampada/tracking_consent');

  Future<TrackingStatus> request() async {
    try {
      final value = await _channel.invokeMethod<String>('request');
      return TrackingStatus.values.asNameMap()[value] ??
          TrackingStatus.unsupported;
    } on MissingPluginException {
      return TrackingStatus.unsupported;
    } on PlatformException {
      return TrackingStatus.unsupported;
    }
  }
}
