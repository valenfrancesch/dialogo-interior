/// Builds a short preview for Lock Screen / widget from raw gospel HTML/plain text.
class LockScreenVersePreview {
  LockScreenVersePreview._();

  static const String _sourceLine =
      'Extraído de la Biblia: Libro del Pueblo de Dios';
  static const int _maxChars = 160;

  /// First sentence or truncated opening after stripping the bible source footer.
  static String fromEvangeliumText(String evangeliumText) {
    if (evangeliumText.isEmpty) return '';
    var t = evangeliumText.replaceFirst(_sourceLine, '').trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return '';

    final dotSpace = t.indexOf('. ');
    if (dotSpace > 0 && dotSpace <= _maxChars) {
      return '${t.substring(0, dotSpace + 1).trim()}';
    }

    if (t.length <= _maxChars) return t;
    return '${t.substring(0, _maxChars - 1)}…';
  }
}
