# Ejemplos de Código - Criptex Spirit

## 📋 Índice
1. [Servicio Firebase](#servicio-firebase)
2. [Pantalla de Reflexión](#pantalla-de-reflexión)
3. [Manejo de Autenticación](#manejo-de-autenticación)
4. [Rutas y Navegación](#rutas-y-navegación)

---

## Servicio Firebase

Crear archivo: `lib/services/firebase_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/entry.dart';
import '../models/user.dart';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ============ USUARIOS ============
  
  /// Obtener usuario actual
  static User? getCurrentUser() => _auth.currentUser;
  
  /// Stream de autenticación
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Crear nuevo usuario y documento en Firestore
  static Future<void> createUserDoc(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  /// Obtener datos del usuario
  static Future<AppUser?> getUserDoc(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? AppUser.fromFirestore(doc) : null;
  }

  /// Actualizar racha de usuario
  static Future<void> updateStreak(String uid, int newStreak) async {
    await _firestore.collection('users').doc(uid).update({
      'streak': newStreak,
      'totalEntries': FieldValue.increment(1),
    });
  }

  // ============ ENTRIES (REFLEXIONES) ============

  /// Crear nueva reflexión
  static Future<String> createEntry(Entry entry) async {
    final docRef = _firestore.collection('entries').doc();
    final entryWithId = entry.copyWith(id: docRef.id);
    await docRef.set(entryWithId.toFirestore());
    return docRef.id;
  }

  /// Obtener reflexiones del usuario (stream en tiempo real)
  static Stream<List<Entry>> getUserEntries(String userId) {
    return _firestore
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Entry.fromFirestore(doc)).toList());
  }

  /// Obtener reflexión por ID
  static Future<Entry?> getEntryById(String entryId) async {
    final doc = await _firestore.collection('entries').doc(entryId).get();
    return doc.exists ? Entry.fromFirestore(doc) : null;
  }

  /// Actualizar reflexión
  static Future<void> updateEntry(Entry entry) async {
    await _firestore.collection('entries').doc(entry.id).update(
      entry.copyWith(updatedAt: DateTime.now()).toFirestore(),
    );
  }

  /// Eliminar reflexión
  static Future<void> deleteEntry(String entryId) async {
    await _firestore.collection('entries').doc(entryId).delete();
  }

  /// Obtener reflexiones por fecha
  static Future<List<Entry>> getEntriesByDate(
    String userId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await _firestore
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return query.docs.map((doc) => Entry.fromFirestore(doc)).toList();
  }

  /// Obtener reflexiones por etiqueta
  static Future<List<Entry>> getEntriesByTag(
    String userId,
    String tag,
  ) async {
    final query = await _firestore
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .where('tags', arrayContains: tag)
        .get();

    return query.docs.map((doc) => Entry.fromFirestore(doc)).toList();
  }

  // ============ TAGS ============

  /// Obtener todos los tags
  static Future<List<String>> getAllTags() async {
    final query = await _firestore.collection('tags').get();
    return query.docs.map((doc) => doc['name'] as String).toList();
  }

  /// Stream de tags
  static Stream<List<String>> tagsStream() {
    return _firestore.collection('tags').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc['name'] as String).toList(),
        );
  }

  // ============ ESTADÍSTICAS ============

  /// Calcular racha de días
  static Future<int> calculateStreak(String userId) async {
    final entries = await _firestore
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    if (entries.docs.isEmpty) return 0;

    int streak = 1;
    DateTime? lastDate = (entries.docs.first['createdAt'] as Timestamp).toDate();

    for (int i = 1; i < entries.docs.length; i++) {
      final currentDate = (entries.docs[i]['createdAt'] as Timestamp).toDate();
      final difference = lastDate!.difference(currentDate).inDays;

      if (difference == 1) {
        streak++;
        lastDate = currentDate;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Obtener total de reflexiones
  static Future<int> getTotalEntries(String userId) async {
    final query = await _firestore
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .count()
        .get();

    return query.count ?? 0;
  }
}
```

---

## Pantalla de Reflexión

Archivo: `lib/screens/reflection_screen.dart` (versión completa)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_tag_chip.dart';
import '../models/tag.dart';
import '../models/entry.dart';
import '../services/firebase_service.dart';

class ReflectionScreen extends StatefulWidget {
  final String? passageTitle;

  const ReflectionScreen({Key? key, this.passageTitle}) : super(key: key);

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final _reflectionController = TextEditingController();
  final List<Tag> _selectedTags = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    if (_reflectionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe una reflexión')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseService.getCurrentUser();
      if (user == null) throw Exception('No hay usuario autenticado');

      final entry = Entry(
        id: '', // Se genera en Firebase
        userId: user.uid,
        passage: widget.passageTitle ?? 'Sin pasaje',
        reflection: _reflectionController.text,
        tags: _selectedTags.map((tag) => tag.name).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.createEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Reflexión guardada')),
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Nueva Reflexión',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado de memoria
                Text(
                  'Memorial del Día',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentMint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Santa Teresa de Ávila',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),

                // Campo de reflexión
                TextField(
                  controller: _reflectionController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '¿Qué me dice Dios hoy?',
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.accentMint,
                        width: 2,
                      ),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Etiquetas
                Text(
                  'Etiquetas',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentMint,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Tag.defaultTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return CustomTagChip(
                      tag: tag,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 100), // Espacio para el botón
              ],
            ),
          ),
          
          // Botón flotante de guardar
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : _saveReflection,
              backgroundColor: _isLoading
                  ? AppTheme.accentMint.withOpacity(0.5)
                  : AppTheme.accentMint,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.primaryDarkBg),
                      ),
                    )
                  : const Icon(Icons.save),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Manejo de Autenticación

Archivo: `lib/services/auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'firebase_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  /// Registrar usuario
  static Future<User?> register(String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);

        // Crear documento en Firestore
        final appUser = AppUser(
          uid: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
        );
        await FirebaseService.createUserDoc(appUser);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Iniciar sesión
  static Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Cerrar sesión
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Restablecer contraseña
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Manejo de errores de autenticación
  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es demasiado débil';
      case 'email-already-in-use':
        return 'El correo ya está registrado';
      case 'invalid-email':
        return 'Correo inválido';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
```

---

## Rutas y Navegación

Archivo: `lib/routes/app_routes.dart`

```dart
import 'package:flutter/material.dart';
import '../screens/reading_screen.dart';
import '../screens/reflection_screen.dart';
import '../screens/timeline_screen.dart';
import '../screens/library_screen.dart';

class AppRoutes {
  static const String reading = '/reading';
  static const String reflection = '/reflection';
  static const String timeline = '/timeline';
  static const String library = '/library';
  static const String entryDetail = '/entry-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case reading:
        return MaterialPageRoute(builder: (_) => const ReadingScreen());
      case reflection:
        return MaterialPageRoute(builder: (_) => const ReflectionScreen());
      case timeline:
        return MaterialPageRoute(builder: (_) => const TimelineScreen());
      case library:
        return MaterialPageRoute(builder: (_) => const LibraryScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
```

---

## Guía de Uso

### 1. Crear una Reflexión
```dart
// En ReflectionScreen
await FirebaseService.createEntry(entry);
```

### 2. Obtener Reflexiones del Usuario
```dart
// En LibraryScreen
StreamBuilder<List<Entry>>(
  stream: FirebaseService.getUserEntries(userId),
  builder: (context, snapshot) {
    // Mostrar reflexiones
  }
)
```

### 3. Calcular Racha
```dart
int streak = await FirebaseService.calculateStreak(userId);
```

---

**¡Listo para implementar! 🚀**
