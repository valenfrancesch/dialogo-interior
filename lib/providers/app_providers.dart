import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gospel_data.dart';
import '../models/prayer_entry.dart';

/// Provider que mantiene el Gospel cargado mientras se navega entre pantallas
class GospelProvider extends ChangeNotifier {
  GospelData? _currentGospel;
  bool _isLoading = false;

  GospelData? get currentGospel => _currentGospel;
  bool get isLoading => _isLoading;

  /// Establece el Gospel actual
  void setGospel(GospelData gospel) {
    _currentGospel = gospel;
    notifyListeners();
  }

  /// Limpia el Gospel
  void clearGospel() {
    _currentGospel = null;
    notifyListeners();
  }

  /// Actualiza el estado de carga
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

/// Provider que mantiene la entrada de oración actual siendo editada
class PrayerEntryProvider extends ChangeNotifier {
  PrayerEntry? _currentEntry;
  PrayerEntry? get currentEntry => _currentEntry;

  /// Inicia una nueva entrada de oración con un Gospel
  void startNewEntry(GospelData gospel) {
    _currentEntry = PrayerEntry(
      userId: '', // Se establece en PrayerRepository
      date: DateTime.now(),
      gospelQuote: gospel.title,
      reflection: '',
    );
    notifyListeners();
  }

  /// Actualiza el texto de reflexión
  void setReflection(String reflection) {
    if (_currentEntry != null) {
      _currentEntry = _currentEntry!.copyWith(reflection: reflection);
      notifyListeners();
    }
  }



  /// Carga una entrada existente para editar
  void loadEntry(PrayerEntry entry) {
    _currentEntry = entry;
    notifyListeners();
  }

  /// Limpia la entrada actual
  void clearEntry() {
    _currentEntry = null;

    notifyListeners();
  }
}

/// Provider que mantiene el tamaño de fuente para el contenido de las lecturas
class ReadingFontSizeProvider extends ChangeNotifier {
  static const String _prefKey = 'readingFontSize';
  static const double defaultSize = 16.0;
  static const double minSize = 12.0;
  static const double maxSize = 22.0;

  double _fontSize = defaultSize;
  double get fontSize => _fontSize;

  ReadingFontSizeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefKey);
    if (saved != null) {
      _fontSize = saved.clamp(minSize, maxSize);
      notifyListeners();
    }
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(minSize, maxSize);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, _fontSize);
  }
}
