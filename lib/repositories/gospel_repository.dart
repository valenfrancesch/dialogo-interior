import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/gospel_data.dart';
import '../services/bible_service.dart';

class GospelRepository {
  static const String _baseUrl = 'https://feed.evangelizo.org/v2/reader.php';

  static GospelData? _cachedGospel;
  static DateTime? _cachedDate;

  /// Obtiene datos completos del evangelio del día y lecturas mediante peticiones paralelas
  static Future<GospelData> fetchGospelData(DateTime date, {String? reference}) async {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day)).inDays.abs();

    try {
      // 1. Si la fecha es de hace más de 30 días, no consultamos la API (Evangelizo no suele tenerlos)
      //    y cargamos el evangelio desde el JSON local.
      if (difference > 30) {
        String? finalReference = reference;
        
        // Si no tenemos referencia, intentamos buscar si existe una reflexión guardada para ese día
        if (finalReference == null) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final docId = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('entries')
                .doc(docId)
                .get();
            
            if (doc.exists) {
              final finalData = doc.data();
              finalReference = finalData?['gospelQuote'] as String?;
            }
          }
        }

        if (finalReference == null) {
          throw Exception("No hay una reflexión guardada para esta fecha lejana.");
        }

        final bibleService = BibleService();
        final parsed = bibleService.parseReference(finalReference);
        String localText = 'Texto no encontrado en la base local.';
        
        if (parsed != null) {
          localText = await bibleService.getVersiclesText(
            parsed['book'], 
            parsed['chapter'], 
            parsed['startVersicle'], 
            parsed['endVersicle']
          );
        }

        return GospelData(
          firstReading: 'Lectura Histórica',
          firstReadingReference: '',
          psalm: 'Lectura desde Historial',
          psalmReference: '',
          title: finalReference,
          evangeliumText: localText.isNotEmpty ? localText : 'Contenido no encontrado en la Biblia local.',
          commentTitle: 'Reflexión histórica',
          commentBody: 'Esta es una lectura recuperada de tu historial. Las lecturas completas y reflexiones de la Iglesia solo están disponibles para el mes actual.',
          commentAuthor: 'Historial',
          commentSource: '',
          date: date,
        );
      }

      // 2. Retorna el caché si corresponde al mismo día
      if (_cachedGospel != null && _cachedDate != null && 
          _cachedDate!.year == date.year && 
          _cachedDate!.month == date.month && 
          _cachedDate!.day == date.day) {
        return _cachedGospel!;
      }

      final dateStr = _formatDate(date);

      // 3. Ejecutar todas las peticiones en paralelo
      final results = await Future.wait([
        _fetchReadingTitle(dateStr, 'FR').catchError((_) => '1ª Lectura'),
        _fetchReadingContent(dateStr, 'FR').catchError((_) => 'No disponible'),
        _fetchReadingTitle(dateStr, 'PS').catchError((_) => 'Salmo'),
        _fetchReadingContent(dateStr, 'PS').catchError((_) => 'No disponible'),
        _fetchReadingTitle(dateStr, 'SR').catchError((_) => 'Lectura del Día'),
        _fetchReadingContent(dateStr, 'SR').catchError((_) => 'No disponible'),
        _fetchReadingTitle(dateStr, 'GSP').catchError((_) => reference ?? 'Evangelio'),
        _fetchReadingContent(dateStr, 'GSP').catchError((_) => 'No disponible'),
        _fetchCommentTitle(dateStr).catchError((_) => 'Reflexión de la Iglesia'),
        _fetchCommentBody(dateStr).catchError((_) => 'No disponible'),
        _fetchCommentAuthor(dateStr).catchError((_) => ''),
        _fetchCommentSource(dateStr).catchError((_) => ''),
        _fetchFeast(dateStr).catchError((_) => ''),
        _fetchReadingLongTitle(dateStr, 'FR').catchError((_) => ''),
        _fetchReadingLongTitle(dateStr, 'PS').catchError((_) => ''),
        _fetchReadingLongTitle(dateStr, 'SR').catchError((_) => ''),
        _fetchReadingLongTitle(dateStr, 'GSP').catchError((_) => ''),
      ]);

      // Handle optional Second Reading
      String? secondReadingRef = results[4];
      String? secondReadingText = results[5];
      String? secondReadingLongTitle = results[15];

      if (secondReadingText == 'No disponible' || secondReadingText.isEmpty ||
          secondReadingRef == 'Lectura del Día' || secondReadingRef.isEmpty) {
        secondReadingRef = null;
        secondReadingText = null;
        secondReadingLongTitle = null;
      }

      // Detect if we actually got a valid response (not HTML junk)
      if (results[1].contains('<!DOCTYPE html>') || results[7].contains('<!DOCTYPE html>')) {
        throw Exception('El servidor devolvió un error (HTML). Intente más tarde.');
      }

      final gospelData = GospelData.fromApiResponses(
        firstReadingReference: results[0] != 'Lectura del Día' ? results[0] : '1ª Lectura',
        firstReading: results[1],
        firstReadingLongTitle: results[13].isNotEmpty ? results[13] : null,
        psalmReference: results[2] != 'Lectura del Día' ? results[2] : 'Salmo',
        psalm: results[3],
        psalmLongTitle: results[14].isNotEmpty ? results[14] : null,
        secondReadingReference: secondReadingRef,
        secondReading: secondReadingText,
        secondReadingLongTitle: secondReadingLongTitle,
        title: results[6],
        gospelLongTitle: results[16].isNotEmpty ? results[16] : null,
        evangeliumText: results[7],
        commentTitle: results[8],
        commentBody: results[9],
        commentAuthor: results[10],
        commentSource: results[11],
        feast: results[12].isNotEmpty ? results[12] : null,
        date: date,
      );

      _cachedGospel = gospelData;
      _cachedDate = date;

      return gospelData;
    } catch (e) {
      throw Exception('Hubo un problema al cargar las lecturas. Por favor, reintente.');
    }
  }

  // Import related files inside GospelRepository (need BibleService)
  // I will add the import to the top in the next step or here if possible.

  /// Generic fetcher for Reading Title/Reference (reading_st)
  /// contentCode: FR, PS, SR, GSP
  static Future<String> _fetchReadingTitle(String dateStr, String contentCode) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=reading_st&content=$contentCode',
        ),
        headers: {
          'User-Agent': 'Criptex-Spirit/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _cleanHtmlText(response.body);
      }
      return 'Lectura del Día';
    } catch (e) {
      return 'Lectura del Día';
    }
  }

  /// Fetcher for Reading Long Title (reading_lt)
  /// contentCode: FR, PS, SR
  static Future<String> _fetchReadingLongTitle(String dateStr, String contentCode) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=reading_lt&content=$contentCode',
        ),
        headers: {
          'User-Agent': 'Criptex-Spirit/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _cleanHtmlText(response.body);
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Generic fetcher for Reading Content (reading)
  /// contentCode: FR, PS, SR, GSP
  static Future<String> _fetchReadingContent(String dateStr, String contentCode) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=reading&content=$contentCode',
        ),
        headers: {
          'User-Agent': 'Criptex-Spirit/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _cleanHtmlText(response.body);
      }
      return 'No disponible';
    } catch (e) {
      return 'No disponible';
    }
  }

    /// Obtiene la fiesta del día (type=feast)
  static Future<String> _fetchFeast(String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=liturgic_t',
        ),
        headers: {
          'User-Agent': 'Criptex-Spirit/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _cleanHtmlText(response.body);
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene el título del comentario de la Iglesia
  static Future<String> _fetchCommentTitle(String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=comment_t',
        ),
        headers: {
          'User-Agent': 'Criptex-Spirit/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _cleanHtmlText(response.body);
      }
      return 'Reflexión de la Iglesia';
    } catch (e) {
      throw Exception('Error fetching comment_t: $e');
    }
  }

  /// Obtiene el cuerpo del comentario
  static Future<String> _fetchCommentBody(String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=comment',
        ),
        headers: {
          'User-Agent': 'Criptex-Spirit/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _cleanHtmlText(response.body);
      }
      return 'Reflexión disponible en evangelizo.org';
    } catch (e) {
      throw Exception('Error fetching comment: $e');
    }
  }

  /// Obtiene el autor del comentario (Ej: San Agustín, Papa Francisco)
  static Future<String> _fetchCommentAuthor(String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=comment_a',
        ),
        headers: {
          'User-Agent': 'Criptex-Spirit/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _cleanHtmlText(response.body);
      }
      return '';
    } catch (e) {
      throw Exception('Error fetching comment_a: $e');
    }
  }

  /// Obtiene la fuente/referencia del comentario
  static Future<String> _fetchCommentSource(String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=comment_s',
        ),
        headers: {
          'User-Agent': 'Criptex-Spirit/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _cleanHtmlText(response.body);
      }
      return '';
    } catch (e) {
      throw Exception('Error fetching comment_s: $e');
    }
  }

  /// Formatea la fecha a YYYYMMDD
  static String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  /// Limpia HTML tags y entidades HTML
  static String _cleanHtmlText(String html) {
    // Parsea el HTML
    final document = html_parser.parse(html);
    
    // Extrae el texto
    final text = document.body?.text ?? '';

    // Limpia espacios en blanco múltiples
    var cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();

    // Filtra el footer de evangelizo.org
    if (cleaned.contains('Para recibir cada mañana')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'Para recibir cada mañana.*?evangeliodeldia\.org'), '')
          .trim();
    }
    
    // Filtra dominios residuales
    cleaned = cleaned.replaceAll(RegExp(r'evangeliodeldia\.org', caseSensitive: false), '').trim();
    
    return cleaned;
  }
}
