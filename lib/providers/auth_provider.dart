import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Provider que maneja el estado de autenticación globalmente
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  
  // TEST MODE: Set to false to use real Firebase, true for demo mode
  static const bool testMode = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;

  AuthProvider() {
    // Initialize auth state listener on creation
    listenToAuthChanges();
    checkInitialAuthState();
  }

  /// Check initial auth state on app startup
  Future<void> checkInitialAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      _isAuthenticated = true;
      _userId = user.uid;
      _userEmail = user.email;
      notifyListeners();
    }
  }

  /// Intenta registrarse con email y contraseña
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String country,
    required String province,
    required DateTime birthDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (testMode) {
        // TEST MODE: Simulate successful registration
        await Future.delayed(const Duration(milliseconds: 500));
        _isAuthenticated = true;
        _userId = 'test_user_123';
        _userEmail = email;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      await _authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        surname: surname,
        country: country,
        province: province,
        birthDate: birthDate,
      );

      _isAuthenticated = true;
      _userId = _authService.currentUserId;
      _userEmail = _authService.currentUserEmail;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Intenta iniciar sesión con email y contraseña
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (testMode) {
        // TEST MODE: Simulate successful login (accept any email/password)
        await Future.delayed(const Duration(milliseconds: 500));
        _isAuthenticated = true;
        _userId = 'test_user_123';
        _userEmail = email;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      _isAuthenticated = true;
      _userId = _authService.currentUserId;
      _userEmail = _authService.currentUserEmail;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.logout();

      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Escucha cambios de autenticación en tiempo real
  void listenToAuthChanges() {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _isAuthenticated = true;
        _userId = user.uid;
        _userEmail = user.email;
      } else {
        _isAuthenticated = false;
        _userId = null;
        _userEmail = null;
      }
      notifyListeners();
    });
  }
}
