import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService with ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._init();
  ConnectivityService._init() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void _init() {
    _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);
    } catch (e) {
      debugPrint('Connectivity check error: $e');
    }
  }

  void _updateStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }

  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
