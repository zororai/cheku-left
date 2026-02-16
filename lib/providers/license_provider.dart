import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/license_service.dart';

class LicenseProvider extends ChangeNotifier {
  final LicenseService _licenseService = LicenseService();

  LicenseStatus? _status;
  bool _isLoading = false;
  String? _error;
  int? _currentButcherId;
  String? _currentButcherName;

  LicenseStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLocked => _status?.isLocked ?? false;
  int get remainingPayments => _status?.remainingPayments ?? 20;
  int get paymentCount => _status?.paymentCount ?? 0;
  int get maxPayments => _status?.maxAllowedPayments ?? 20;

  void setCurrentButcher({
    required int butcherId,
    required String butcherName,
  }) {
    _currentButcherId = butcherId;
    _currentButcherName = butcherName;
  }

  Future<void> checkLicenseStatus({
    required int butcherId,
    String? token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _status = await _licenseService.checkLicenseStatus(
        butcherId: butcherId,
        token: token,
      );

      if (_status!.isLocked) {
        await _saveLockStatus(true);
      }
    } catch (e) {
      debugPrint('Error checking license: $e');
      _error = 'Failed to check license status';

      final cachedLocked = await _getCachedLockStatus();
      if (cachedLocked) {
        _status = LicenseStatus.locked();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<LicenseStatus> incrementPaymentAndCheck({
    required int butcherId,
    required String butcherName,
  }) async {
    try {
      _status = await _licenseService.incrementPaymentCount(
        butcherId: butcherId,
        butcherName: butcherName,
      );

      if (_status!.isLocked) {
        await _saveLockStatus(true);
      }

      notifyListeners();
      return _status!;
    } catch (e) {
      debugPrint('Error incrementing payment: $e');
      return _status ?? LicenseStatus.unlocked();
    }
  }

  Future<bool> submitUnlockCode({
    required int butcherId,
    required String code,
    String? token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _licenseService.submitUnlockCode(
        butcherId: butcherId,
        code: code,
        token: token,
      );

      if (result.success) {
        _status = LicenseStatus.unlocked();
        await _saveLockStatus(false);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error submitting unlock code: $e');
      _error = 'Connection error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> registerDevice({
    required int butcherId,
    required String butcherName,
  }) async {
    await _licenseService.registerDevice(
      butcherId: butcherId,
      butcherName: butcherName,
    );
  }

  Future<void> _saveLockStatus(bool isLocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('license_is_locked', isLocked);
  }

  Future<bool> _getCachedLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('license_is_locked') ?? false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
