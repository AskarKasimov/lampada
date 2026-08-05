import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_network_status.dart';
import 'network_status.dart';

/// Общий для приложения шлюз проверки сетевого интерфейса.
final networkStatusProvider = Provider<NetworkStatus>(
  (ref) => ConnectivityNetworkStatus(),
);
