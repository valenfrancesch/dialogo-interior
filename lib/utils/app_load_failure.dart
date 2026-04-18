import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

/// Errores de carga con copy claro para el usuario (red / Firestore / timeout).
class AppLoadFailure implements Exception {
  AppLoadFailure({
    required this.title,
    required this.message,
    this.showUseCachedHint = false,
  });

  final String title;
  final String message;
  final bool showUseCachedHint;

  @override
  String toString() => message;

  static AppLoadFailure from(Object error, {bool offerCachedHint = true}) {
    final hint = offerCachedHint;
    final text = error.toString().toLowerCase();

    if (error is TimeoutException || text.contains('timeout')) {
      return AppLoadFailure(
        title: 'Tiempo de espera agotado',
        message: 'La conexión tardó demasiado. Comprobá tu red e intentá de nuevo.',
        showUseCachedHint: hint,
      );
    }

    if (error is FirebaseException) {
      final code = error.code;
      if (code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          code == 'network-request-failed' ||
          code == 'resource-exhausted') {
        return AppLoadFailure(
          title: 'Sin conexión o servicio no disponible',
          message:
              'No pudimos alcanzar la nube. Verificá tu conexión e intentá otra vez.',
          showUseCachedHint: hint,
        );
      }
    }

    if (_looksLikeOffline(error)) {
      return AppLoadFailure(
        title: 'Sin conexión a internet',
        message: 'No pudimos conectar con los servidores. Comprobá Wi‑Fi o datos móviles.',
        showUseCachedHint: hint,
      );
    }

    return AppLoadFailure(
      title: 'No pudimos cargar el contenido',
      message:
          'Ocurrió un problema inesperado. Intentá de nuevo en unos segundos.\n\n'
          'Si el problema continúa, comprobá tu conexión.',
      showUseCachedHint: false,
    );
  }

  static bool _looksLikeOffline(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('clientexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('connection aborted') ||
        s.contains('host lookup failed') ||
        s.contains('no address associated with hostname');
  }
}
