import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_status.dart';

/// Адаптер платформенной информации о подключённых интерфейсах.
class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    try {
      final connections = await _connectivity.checkConnectivity();
      return connections.any(
        (connection) => connection != ConnectivityResult.none,
      );
    } on Object {
      // Неизвестная ошибка плагина не должна выдавать интернет за офлайн.
      // В таком случае HTTP сам проверит доступность и вернёт обычную ошибку.
      return true;
    }
  }
}
