// lib/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Emits distinct lists of active connectivity types
  Stream<List<ConnectivityResult>> get onConnectionChange =>
      _connectivity.onConnectivityChanged;
}
