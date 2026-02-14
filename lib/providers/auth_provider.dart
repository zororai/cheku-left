import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isAuthenticated = false;
  int? _userId;
  int? _butcherId;
  String? _username;
  String? _fullName;
  String? _role;
  String? _butcherName;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  int? get userId => _userId;
  int? get butcherId => _butcherId;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get role => _role;
  String? get butcherName => _butcherName;
  bool get isLoading => _isLoading;
  bool get isAdmin => _role == 'admin';
  bool get isManager => _role == 'manager';
  bool get isCashier => _role == 'cashier';

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('is_authenticated') ?? false;
      _userId = prefs.getInt('user_id');
      _butcherId = prefs.getInt('butcher_id');
      _username = prefs.getString('username');
      _fullName = prefs.getString('full_name');
      _role = prefs.getString('role');
      _butcherName = prefs.getString('butcher_name');
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    }

    _isLoading = false;
    notifyListeners();
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
