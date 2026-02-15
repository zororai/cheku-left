import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? userData;
  final String? token;
  final int? statusCode;

  AuthResult({
    required this.success,
    this.message,
    this.userData,
    this.token,
    this.statusCode,
  });
}

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _baseUrlKey = 'api_url';
  static const String _defaultBaseUrl = 'https://api.chekuleft.co.zw';

  Future<String> get _baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final baseUrl = await _baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'] as String?;
        if (token != null) {
          await saveToken(token);
        }

        return AuthResult(
          success: true,
          userData: data['user'] as Map<String, dynamic>?,
          token: token,
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        return AuthResult(
          success: false,
          message: 'Invalid email or password',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        final errorType = data['error_type'] ?? '';
        if (errorType == 'subscription_expired') {
          return AuthResult(
            success: false,
            message: 'Subscription expired',
            statusCode: response.statusCode,
          );
        } else if (errorType == 'account_suspended') {
          return AuthResult(
            success: false,
            message: 'Account suspended',
            statusCode: response.statusCode,
          );
        }
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Access denied',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 422) {
        final errors = data['errors'] as Map<String, dynamic>?;
        final firstError = errors?.values.first;
        return AuthResult(
          success: false,
          message: firstError is List ? firstError.first : 'Validation error',
          statusCode: response.statusCode,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return AuthResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  Future<AuthResult> checkAuthStatus() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResult(success: false, message: 'No token');
      }

      final baseUrl = await _baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResult(
          success: true,
          userData: data['user'] as Map<String, dynamic>?,
          token: token,
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        await deleteToken();
        return AuthResult(
          success: false,
          message: 'Session expired',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        final errorType = data['error_type'] ?? '';
        return AuthResult(
          success: false,
          message: errorType == 'subscription_expired'
              ? 'Subscription expired'
              : 'Account suspended',
          statusCode: response.statusCode,
        );
      }

      return AuthResult(
        success: false,
        message: 'Authentication failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Check auth error: $e');
      return AuthResult(success: false, message: 'Network error');
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        final baseUrl = await _baseUrl;
        await http.post(
          Uri.parse('$baseUrl/api/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await deleteToken();
    }
  }
}
