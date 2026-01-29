import 'package:flutter/material.dart';
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
  List<String> _currentTags = [];

  PrayerEntry? get currentEntry => _currentEntry;
  List<String> get currentTags => _currentTags;

  /// Inicia una nueva entrada de oración con un Gospel
  void startNewEntry(GospelData gospel) {
    _currentEntry = PrayerEntry(
      userId: '', // Se establece en PrayerRepository
      date: DateTime.now(),
      gospelQuote: gospel.title,
      reflection: '',
      tags: [],
    );
    _currentTags = [];
    notifyListeners();
  }

  /// Actualiza el texto de reflexión
  void setReflection(String reflection) {
    if (_currentEntry != null) {
      _currentEntry = _currentEntry!.copyWith(reflection: reflection);
      notifyListeners();
    }
  }

  /// Añade una etiqueta
  void addTag(String tag) {
    if (!_currentTags.contains(tag) && tag.isNotEmpty) {
      _currentTags.add(tag);
      _updateEntryTags();
    }
  }

  /// Elimina una etiqueta
  void removeTag(String tag) {
    _currentTags.remove(tag);
    _updateEntryTags();
  }

  /// Actualiza los tags en la entrada
  void _updateEntryTags() {
    if (_currentEntry != null) {
      _currentEntry = _currentEntry!.copyWith(tags: _currentTags);
      notifyListeners();
    }
  }

  /// Carga una entrada existente para editar
  void loadEntry(PrayerEntry entry) {
    _currentEntry = entry;
    _currentTags = List.from(entry.tags);
    notifyListeners();
  }

  /// Limpia la entrada actual
  void clearEntry() {
    _currentEntry = null;
    _currentTags = [];
    notifyListeners();
  }
}
