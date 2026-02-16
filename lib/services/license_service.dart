import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class LicenseStatus {
  final bool isLocked;
  final int remainingPayments;
  final int paymentCount;
  final int maxAllowedPayments;

  LicenseStatus({
    required this.isLocked,
    required this.remainingPayments,
    required this.paymentCount,
    required this.maxAllowedPayments,
  });

  factory LicenseStatus.fromJson(Map<String, dynamic> json) {
    final maxPayments = json['max_allowed_payments'] ?? 20;
    final count = json['payment_count'] ?? 0;
    return LicenseStatus(
      isLocked: json['is_locked'] ?? false,
      remainingPayments: json['remaining_payments'] ?? (maxPayments - count),
      paymentCount: count,
      maxAllowedPayments: maxPayments,
    );
  }

  factory LicenseStatus.unlocked() {
    return LicenseStatus(
      isLocked: false,
      remainingPayments: 20,
      paymentCount: 0,
      maxAllowedPayments: 20,
    );
  }

  factory LicenseStatus.locked() {
    return LicenseStatus(
      isLocked: true,
      remainingPayments: 0,
      paymentCount: 20,
      maxAllowedPayments: 20,
    );
  }
}

class UnlockResult {
  final bool success;
  final String message;

  UnlockResult({required this.success, required this.message});

  factory UnlockResult.fromJson(Map<String, dynamic> json) {
    return UnlockResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class LicenseService {
  static const String _baseUrl = 'https://chekuleftpos.co.zw';
  static const Duration _timeout = Duration(seconds: 30);

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> _getDeviceId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return 'unknown';
    }
  }

  Future<String> _getDeviceName() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return '${androidInfo.brand} ${androidInfo.model}';
    } catch (e) {
      debugPrint('Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  Future<LicenseStatus> checkLicenseStatus({
    required int butcherId,
    String? token,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/license/status?butcher_id=$butcherId'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LicenseStatus.fromJson(data);
      } else {
        debugPrint('License check failed: ${response.statusCode}');
        return LicenseStatus.unlocked();
      }
    } catch (e) {
      debugPrint('Error checking license status: $e');
      return LicenseStatus.unlocked();
    }
  }

  Future<LicenseStatus> incrementPaymentCount({
    required int butcherId,
    required String butcherName,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/license/increment'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'butcher_id': butcherId,
              'butcher_name': butcherName,
              'device_id': deviceId,
              'device_name': deviceName,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LicenseStatus.fromJson(data);
      } else {
        debugPrint('Increment payment failed: ${response.statusCode}');
        return LicenseStatus.unlocked();
      }
    } catch (e) {
      debugPrint('Error incrementing payment count: $e');
      return LicenseStatus.unlocked();
    }
  }

  Future<UnlockResult> submitUnlockCode({
    required int butcherId,
    required String code,
    String? token,
  }) async {
    try {
      final deviceId = await _getDeviceId();

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/license/unlock'),
            headers: headers,
            body: jsonEncode({
              'butcher_id': butcherId,
              'device_id': deviceId,
              'unlock_code': code,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UnlockResult.fromJson(data);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final data = jsonDecode(response.body);
        return UnlockResult(
          success: false,
          message: data['message'] ?? 'Invalid unlock code',
        );
      } else {
        return UnlockResult(
          success: false,
          message: 'Server error. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Error submitting unlock code: $e');
      return UnlockResult(
        success: false,
        message: 'Connection error. Please check your internet.',
      );
    }
  }

  Future<bool> registerDevice({
    required int butcherId,
    required String butcherName,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/license/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'butcher_id': butcherId,
              'butcher_name': butcherName,
              'device_id': deviceId,
              'device_name': deviceName,
            }),
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error registering device: $e');
      return false;
    }
  }
}
