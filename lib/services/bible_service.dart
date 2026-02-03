import 'dart:convert';
import 'package:flutter/services.dart';

class BibleService {
  static final BibleService _instance = BibleService._internal();

  factory BibleService() {
    return _instance;
  }

  BibleService._internal();

  List<dynamic>? _gospelsData;

  /// Loads the gospels JSON from assets
  Future<void> loadGospels() async {
    if (_gospelsData != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/bible/gospels.json');
      _gospelsData = json.decode(jsonString);
    } catch (e) {
      print('Error loading gospels data: $e');
      rethrow;
    }
  }

  /// Parses a reference string like "Mc 1, 1-4" or "Juan 3:16"
  /// Returns a map with {book, chapter, startVersicle, endVersicle}
  /// Note: This is a heuristic parser tailored to common Spanish formats.
  Map<String, dynamic>? parseReference(String reference) {
    try {
      // Normalize: remove extra spaces
      String ref = reference.trim();
      
      // Extract Book
      // Matches "Mc", "Mt", "Lc", "Jn", "Marcos", "Mateo", "Lucas", "Juan"
      // followed by space and numbers
      
      // Simple mapping of abbreviations to Book Names in JSON
      String? bookName;
      String remaining = ref;

      if (ref.startsWith('Mc') || ref.toLowerCase().startsWith('marcos')) {
        bookName = 'Marcos';
        remaining = ref.replaceAll(RegExp(r'^(Mc|Marcos)\.?\s*'), '');
      } else if (ref.startsWith('Mt') || ref.toLowerCase().startsWith('mateo')) {
        bookName = 'Mateo';
        remaining = ref.replaceAll(RegExp(r'^(Mt|Mateo)\.?\s*'), '');
      } else if (ref.startsWith('Lc') || ref.toLowerCase().startsWith('lucas')) {
        bookName = 'Lucas';
        remaining = ref.replaceAll(RegExp(r'^(Lc|Lucas)\.?\s*'), '');
      } else if (ref.startsWith('Jn') || ref.toLowerCase().startsWith('juan')) {
        bookName = 'Juan';
        remaining = ref.replaceAll(RegExp(r'^(Jn|Juan)\.?\s*'), '');
      }

      if (bookName == null) return null;

      // Extract Chapter
      // Format usually: "1, 1-4" or "1:1-4" or "1 1-4"
      // Split by comma, colon or space to get chapter
      
      // Let's rely on the first separator that isn't a digit
      final chapterMatch = RegExp(r'^(\d+)').firstMatch(remaining);
      if (chapterMatch == null) return null;
      
      int chapter = int.parse(chapterMatch.group(1)!);
      
      // Remove chapter and separator (like ", " or ": " or " ")
      String versiclesPart = remaining.substring(chapterMatch.end).trim();
      if (versiclesPart.startsWith(',') || versiclesPart.startsWith(':')) {
         versiclesPart = versiclesPart.substring(1).trim();
      }

      // Extract Versicles
      // Format: "1-4" or "12" or "3,5" (we might just support range for now for simplicity as per requirement)
      // If valid range "1-4"
      int startVersicle = 0;
      int endVersicle = 0;


      if (versiclesPart.contains('-')) {
        final parts = versiclesPart.split('-');
        startVersicle = int.tryParse(parts[0].trim()) ?? 0;

        if (parts.length > 1) {
          // CORRECCIÓN: Quitamos cualquier carácter que no sea dígito (como el punto)
          String endPartCleaned = parts[1].trim().replaceAll(RegExp(r'[^0-9]'), '');
          endVersicle = int.tryParse(endPartCleaned) ?? startVersicle;
        } else {
          endVersicle = startVersicle;
        }

      } else {
        // Single versicle
        startVersicle = int.tryParse(versiclesPart.trim()) ?? 0;
        endVersicle = startVersicle;
      }

      return {
        'book': bookName,
        'chapter': chapter,
        'startVersicle': startVersicle,
        'endVersicle': endVersicle,
      };

    } catch (e) {
      print('Error parsing reference: $e');
      return null;
    }
  }

  /// Retrieves the text for a given book, chapter and versicle range
  Future<String> getVersiclesText(String book, int chapter, int startVersicle, int endVersicle) async {
    await loadGospels();
    if (_gospelsData == null) return 'Datos no disponibles';

    final bookData = _gospelsData!.firstWhere(
      (b) => b['book'] == book,
      orElse: () => null,
    );

    if (bookData == null) return 'Libro no encontrado';

    List<dynamic> versicles = bookData['versicles'];
    
    // Filter by chapter
    // Note: JSON structure seems to be flat list of versicles with "chapter" and "versicle" fields as strings?
    // Let's double check the JSON structure observed earlier.
    // JSON: { "book": "Mateo", "versicles": [ { "chapter": "1", "versicle": "1", "text": "..." }, ... ] }
    
    final StringBuffer buffer = StringBuffer();

    for (var v in versicles) {
      int vChapter = int.tryParse(v['chapter'].toString()) ?? 0;
      
      // Handle versicle as string which might be "21", "21a", "21-22"
      String vStr = v['versicle'].toString();
      int vNumStart = 0;
      int vNumEnd = 0;

      if (vStr.contains('-')) {
        // It's a range in the JSON itself
        final parts = vStr.split('-');
        vNumStart = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        vNumEnd = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? vNumStart;
      } else {
        // It's a single number, possibly with letters "21a"
        vNumStart = int.tryParse(vStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        vNumEnd = vNumStart;
      }

      if (vChapter == chapter) {
        // Check overlap between requested range [startVersicle, endVersicle] 
        // and current versicle range [vNumStart, vNumEnd]
        // We include if any part overlaps
        if (vNumEnd >= startVersicle && vNumStart <= endVersicle) {
          buffer.writeln('${vStr}. ${v['text']}');
        }
      }
    }

    return buffer.toString().trim();
  }
}
