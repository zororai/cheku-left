import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isAuthenticated = false;
  int? _userId;
  int? _butcherId;
  String? _username;
  String? _fullName;
  String? _role;
  String? _butcherName;
  String? _email;
  String? _token;
  bool _isLoading = false;
  String? _authError;
  int? _authErrorCode;

  final AuthService _authService = AuthService.instance;

  bool get isAuthenticated => _isAuthenticated;
  int? get userId => _userId;
  int? get butcherId => _butcherId;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get role => _role;
  String? get butcherName => _butcherName;
  String? get email => _email;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get authError => _authError;
  int? get authErrorCode => _authErrorCode;
  bool get isSubscriptionExpired =>
      _authErrorCode == 403 && _authError == 'Subscription expired';
  bool get isAccountSuspended =>
      _authErrorCode == 403 && _authError == 'Account suspended';
  bool get isAdmin => _role == 'admin' || _role == 'owner';
  bool get isOwner => _role == 'owner';
  bool get isManager => _role == 'manager';
  bool get isCashier => _role == 'cashier';

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedAuth = prefs.getBool('is_authenticated') ?? false;
      _userId = prefs.getInt('user_id');
      _butcherId = prefs.getInt('butcher_id');
      _username = prefs.getString('username');
      _fullName = prefs.getString('full_name');
      _role = prefs.getString('role');
      _butcherName = prefs.getString('butcher_name');
      _email = prefs.getString('email');
      _token = await _authService.getToken();

      // Require valid userId and butcherId to be authenticated
      _isAuthenticated = storedAuth && _userId != null && _butcherId != null;

      // If invalid auth state, clear stored data
      if (!_isAuthenticated && storedAuth) {
        await prefs.setBool('is_authenticated', false);
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithApi(String email, String password) async {
    _isLoading = true;
    _authError = null;
    _authErrorCode = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      if (result.success && result.userData != null) {
        _isAuthenticated = true;
        _userId = result.userData!['id'] as int?;
        _butcherId = result.userData!['butcher_id'] as int?;
        _username = result.userData!['name'] as String?;
        _email = result.userData!['email'] as String?;
        _fullName = result.userData!['name'] as String?;
        _role = result.userData!['role'] as String?;
        _token = result.token;

        if (result.userData!['butcher'] != null) {
          final butcher = result.userData!['butcher'] as Map<String, dynamic>;
          _butcherName = butcher['name'] as String?;
        }

        // Save to SQLite for offline login
        if (_userId != null && _butcherId != null) {
          await _db.saveUserFromApi(
            id: _userId!,
            butcherId: _butcherId!,
            email: email,
            passwordHash: password,
            fullName: _fullName ?? email,
            role: _role ?? 'cashier',
            butcherName: _butcherName,
          );
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        if (_userId != null) await prefs.setInt('user_id', _userId!);
        if (_butcherId != null) await prefs.setInt('butcher_id', _butcherId!);
        if (_username != null) await prefs.setString('username', _username!);
        if (_email != null) await prefs.setString('email', _email!);
        if (_fullName != null) await prefs.setString('full_name', _fullName!);
        if (_role != null) await prefs.setString('role', _role!);
        if (_butcherName != null) {
          await prefs.setString('butcher_name', _butcherName!);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = result.message;
        _authErrorCode = result.statusCode;
      }
    } catch (e) {
      debugPrint('Error during API login: $e');
      _authError = 'Network error. Trying offline login...';

      // Try offline login from SQLite
      final offlineResult = await _loginOffline(email, password);
      if (offlineResult) {
        _authError = null;
        return true;
      }
      _authError = 'Login failed. Check credentials or connect to internet.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> _loginOffline(String email, String password) async {
    try {
      final user = await _db.authenticateUserByEmail(email, password);

      if (user != null) {
        _isAuthenticated = true;
        _userId = user['id'] as int;
        _butcherId = user['butcher_id'] as int;
        _username = user['username'] as String;
        _fullName = user['full_name'] as String;
        _role = user['role'] as String;
        _email = email;

        if (user['butcher_shop'] != null) {
          final butcherShop = user['butcher_shop'] as Map<String, dynamic>;
          _butcherName = butcherShop['name'] as String?;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        await prefs.setInt('user_id', _userId!);
        await prefs.setInt('butcher_id', _butcherId!);
        await prefs.setString('username', _username!);
        await prefs.setString('full_name', _fullName!);
        await prefs.setString('role', _role!);
        if (_email != null) await prefs.setString('email', _email!);
        if (_butcherName != null) {
          await prefs.setString('butcher_name', _butcherName!);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error during offline login: $e');
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _db.authenticateUser(username, password);

      if (user != null) {
        _isAuthenticated = true;
        _userId = user['id'] as int;
        _butcherId = user['butcher_id'] as int;
        _username = user['username'] as String;
        _fullName = user['full_name'] as String;
        _role = user['role'] as String;

        // Get butcher shop name
        if (user['butcher_shop'] != null) {
          final butcherShop = user['butcher_shop'] as Map<String, dynamic>;
          _butcherName = butcherShop['name'] as String;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        await prefs.setInt('user_id', _userId!);
        await prefs.setInt('butcher_id', _butcherId!);
        await prefs.setString('username', _username!);
        await prefs.setString('full_name', _fullName!);
        await prefs.setString('role', _role!);
        if (_butcherName != null) {
          await prefs.setString('butcher_name', _butcherName!);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error during login: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _isAuthenticated = false;
      _userId = null;
      _butcherId = null;
      _username = null;
      _fullName = null;
      _role = null;
      _butcherName = null;
    } catch (e) {
      debugPrint('Error during logout: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
