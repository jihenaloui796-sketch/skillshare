import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> bootstrap() async {
    _isAuthenticated = await _authService.hasToken();
    notifyListeners();
    if (_isAuthenticated) {
      await NotificationService.instance.syncTokenWithBackend();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.login(email: email, password: password);
      _isAuthenticated = true;
      await NotificationService.instance.syncTokenWithBackend();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(
      {required String email,
      required String password,
      required String fullName}) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.register(
          email: email, password: password, fullName: fullName);
      _isAuthenticated = true;
      await NotificationService.instance.syncTokenWithBackend();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    // Keep the last sent token cached; it will be refreshed on next login/bootstrap.
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
