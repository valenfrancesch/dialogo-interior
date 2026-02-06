import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/gospel_data.dart';

class GospelRepository {
  static const String _baseUrl = 'http://feed.evangelizo.org/v2/reader.php';

  /// Obtiene datos completos del evangelio del día y lecturas mediante peticiones paralelas
  static Future<GospelData> fetchGospelData(DateTime date) async {
    try {
      final dateStr = _formatDate(date);

      // Ejecutar todas las peticiones en paralelo
      final results = await Future.wait([
        _fetchReadingTitle(dateStr, 'FR'), // 1ª Lectura Ref
        _fetchReadingContent(dateStr, 'FR'), // 1ª Lectura Texto
        _fetchReadingTitle(dateStr, 'PS'), // Salmo Ref
        _fetchReadingContent(dateStr, 'PS'), // Salmo Texto
        _fetchReadingTitle(dateStr, 'SR'), // 2ª Lectura Ref (Opcional)
        _fetchReadingContent(dateStr, 'SR'), // 2ª Lectura Texto (Opcional)
        _fetchReadingTitle(dateStr, 'GSP'), // Evangelio Ref (GSP)
        _fetchReadingContent(dateStr, 'GSP'), // Evangelio Texto
        _fetchCommentTitle(dateStr), // Título del comentario
        _fetchCommentBody(dateStr), // Cuerpo del comentario
        _fetchCommentAuthor(dateStr), // Autor del comentario
        _fetchCommentSource(dateStr), // Fuente/Referencia
        _fetchFeast(dateStr), // Fiesta
      ]);

      // Handle optional Second Reading
      String? secondReadingRef = results[4];
      String? secondReadingText = results[5];

      // Reset empty/error responses for optional SR
      if (secondReadingText == 'No disponible' || secondReadingText.isEmpty ||
          secondReadingRef == 'Lectura del Día' || secondReadingRef.isEmpty) {
        secondReadingRef = null;
        secondReadingText = null;
      }

      return GospelData.fromApiResponses(
        firstReadingReference: results[0] != 'Lectura del Día' ? results[0] : '1ª Lectura',
        firstReading: results[1],
        psalmReference: results[2] != 'Lectura del Día' ? results[2] : 'Salmo',
        psalm: results[3],
        secondReadingReference: secondReadingRef,
        secondReading: secondReadingText,
        title: results[6],
        evangeliumText: results[7],
        commentTitle: results[8],
        commentBody: results[9],
        commentAuthor: results[10],
        commentSource: results[11],
        feast: results[12].isNotEmpty ? results[12] : null,
        date: date,
      );
    } catch (e) {
      throw Exception('Error al obtener datos del evangelio: $e');
    }
  }

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
      // For optional readings like SR, we just return default valid string, handled in main fetch
      return 'Lectura del Día';
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
