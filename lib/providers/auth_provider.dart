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
  String? _userName;
  String? _userSurname;
  
  // TEST MODE: Set to false to use real Firebase, true for demo mode
  static const bool testMode = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userSurname => _userSurname;

  /// Returns the full formatted name or a fallback
  String get userFullName {
    if (_userName != null && _userSurname != null) {
      return '$_userName $_userSurname'.trim();
    }
    return _userName ?? _userEmail?.split('@').first ?? 'Usuario';
  }

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
      await _fetchUserProfile();
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfile() async {
    final profile = await _authService.getUserProfile();
    if (profile != null) {
      _userName = profile['name'] as String?;
      _userSurname = profile['surname'] as String?;
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
      await _fetchUserProfile();
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
      await _fetchUserProfile();
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
      _userName = null;
      _userSurname = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envía email para restablecer contraseña
  Future<bool> sendPasswordReset(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.sendPasswordResetEmail(email);

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

  /// Elimina la cuenta y todos los datos del usuario
  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.deleteAccount();

      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      _userName = null;
      _userSurname = null;
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

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Escucha cambios de autenticación en tiempo real
  void listenToAuthChanges() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        _isAuthenticated = true;
        _userId = user.uid;
        _userEmail = user.email;
        await _fetchUserProfile();
      } else {
        _isAuthenticated = false;
        _userId = null;
        _userEmail = null;
        _userName = null;
        _userSurname = null;
      }
      notifyListeners();
    });
  }
}
