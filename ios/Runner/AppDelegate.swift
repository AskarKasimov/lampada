import AppTrackingTransparency
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Без делегата уведомление, пришедшее при открытом приложении, система
    // гасит молча, а тап по нему не доходит до flutter_local_notifications.
    // FlutterAppDelegate уже реализует UNUserNotificationCenterDelegate —
    // достаточно его назначить.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TrackingConsent") {
      TrackingConsentChannel.register(messenger: registrar.messenger())
    }
  }
}

/// Запрос App Tracking Transparency для AppMetrica (lib/core/analytics/tracking_consent.dart).
/// Свой канал вместо пакета: iOS-плагины подключены через Swift Package Manager.
enum TrackingConsentChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lampada/tracking_consent", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "request" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard #available(iOS 14, *) else {
        result("unsupported")
        return
      }
      requestWhenActive { result(name(of: $0)) }
    }
  }

  // Окно система показывает только активному приложению: запрос, сделанный
  // до этого, сразу вернёт notDetermined без окна. Поэтому ждём активации.
  @available(iOS 14, *)
  private static func requestWhenActive(
    _ completion: @escaping (ATTrackingManager.AuthorizationStatus) -> Void
  ) {
    let request = {
      ATTrackingManager.requestTrackingAuthorization { status in
        DispatchQueue.main.async { completion(status) }
      }
    }
    if UIApplication.shared.applicationState == .active {
      request()
      return
    }
    var observer: NSObjectProtocol?
    observer = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { _ in
      if let observer { NotificationCenter.default.removeObserver(observer) }
      request()
    }
  }

  @available(iOS 14, *)
  private static func name(of status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    case .denied: return "denied"
    case .authorized: return "authorized"
    @unknown default: return "notDetermined"
    }
  }
}
