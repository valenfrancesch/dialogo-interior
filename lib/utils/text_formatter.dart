class TextFormatter {
  /// Formatea el texto de las lecturas para que no sean un bloque denso
  /// Inserta saltos de línea adicionales después de puntos finales
  static String formatReadingText(String text) {
    if (text.isEmpty) return text;

    // Primero normalizamos los saltos de línea existentes
    String normalized = text.replaceAll(RegExp(r'\n+'), '\n');

    // Reemplaza ". " por ".\n\n" SOLO si no está seguido ya de un salto de línea
    return normalized.replaceAllMapped(
      RegExp(r'\. +([A-ZÁÉÍÓÚÑ])'),
      (match) => '.\n\n${match.group(1)}'
    );
  }

  /// Formatea el texto de los Salmos para que cada versículo esté en una línea nueva
  static String formatPsalm(String text) {
    if (text.isEmpty) return text;

    // Los salmos a menudo vienen con R. (Respuesta) seguido de texto
    // O números indicando versículos.
    // Intentamos separar por líneas lógicas.
    
    String formatted = text;
    
    // Si viene "R." pegado, lo separamos
    formatted = formatted.replaceAll('R.', '\nR.');

    // Heurística: si hay oraciones largas, tratamos de cortar
    // Pero lo mejor para salmos es detectar patrones de fin de verso.
    // Si el texto plano no tiene saltos, tratamos de inferir con puntuación fuerte.
    
    formatted = formatted.replaceAll('. ', '.\n');
    formatted = formatted.replaceAll('; ', ';\n');
    
    return formatted;
  }
}
