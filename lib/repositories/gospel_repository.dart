import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/gospel_data.dart';

class GospelRepository {
  static const String _baseUrl = 'http://feed.evangelizo.org/v2/reader.php';

  /// Obtiene datos completos del evangelio del día mediante peticiones paralelas
  static Future<GospelData> fetchGospelData(DateTime date) async {
    try {
      final dateStr = _formatDate(date);

      // Ejecutar todas las peticiones en paralelo
      final results = await Future.wait([
        _fetchReadingSt(dateStr), // Título/Cita (Juan 3:16-21)
        _fetchReading(dateStr), // Texto completo del evangelio
        _fetchCommentTitle(dateStr), // Título del comentario
        _fetchCommentBody(dateStr), // Cuerpo del comentario
        _fetchCommentAuthor(dateStr), // Autor del comentario
        _fetchCommentSource(dateStr), // Fuente/Referencia
      ]);

      return GospelData.fromApiResponses(
        title: results[0],
        evangeliumText: results[1],
        commentTitle: results[2],
        commentBody: results[3],
        commentAuthor: results[4],
        commentSource: results[5],
        date: date,
      );
    } catch (e) {
      throw Exception('Error al obtener datos del evangelio: $e');
    }
  }

  /// Obtiene la cita bíblica (Ej: Juan 3:16-21)
  static Future<String> _fetchReadingSt(String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=reading_st&content=GSP',
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
      throw Exception('Error fetching reading_st: $e');
    }
  }

  /// Obtiene el texto completo del evangelio
  static Future<String> _fetchReading(String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?date=$dateStr&lang=SP&type=reading&content=GSP',
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
      throw Exception('Error fetching reading: $e');
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

    return cleaned;
  }
}
