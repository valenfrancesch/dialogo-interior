import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actual
  User? get currentUser => _auth.currentUser;

  /// Verifica si está autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  /// Registra un nuevo usuario con email, contraseña y datos de perfil
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String country,
    required String province,
    required DateTime birthDate,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save user profile data to Firestore
      final uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'surname': surname,
        'country': country,
        'province': province,
        'birthDate': Timestamp.fromDate(birthDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  /// Inicia sesión con email y contraseña
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Envía un email para resetear contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Actualiza el perfil del usuario
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await currentUser?.updateProfile(
        displayName: displayName,
        photoURL: photoUrl,
      );
      await currentUser?.reload();
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Maneja excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este email ya está registrado.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'user-not-found':
        return 'No existe cuenta con este email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }

  /// Verifica si el email ya está registrado (verificación básica)
  /// Nota: Esta es una verificación simple. Para mejor UX, se recomienda
  /// mostrar el error en el formulario cuando intente registrarse
  Future<bool> isEmailRegistered(String email) async {
    try {
      await loginWithEmail(email: email, password: 'check');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return false;
      }
      return true; // Email existe
    }
  }

  /// Obtiene el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Obtiene el email del usuario actual
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Verifica si el email está verificado
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Envía email de verificación
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Error al enviar email de verificación: $e');
    }
  }

  /// Elimina la cuenta del usuario actual (peligroso)
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Error al eliminar cuenta: $e');
    }
  }
}
