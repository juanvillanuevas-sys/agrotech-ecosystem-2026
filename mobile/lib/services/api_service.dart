import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion.dart';
import '../models/lectura.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = AuthService.baseUrl;

  // ── Headers autorizados ────────────────────────────────────────────────────

  Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Estaciones ─────────────────────────────────────────────────────────────

  Future<List<Estacion>> fetchEstaciones() async {
    final response = await http
        .get(Uri.parse('$baseUrl/estaciones/'), headers: await _headers())
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Estacion.fromJson(e)).toList();
    }
    if (response.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    throw Exception('Error del servidor: ${response.statusCode}');
  }

  Future<bool> crearEstacion({
    required String nombre,
    required String ubicacion,
    double? latitud,
    double? longitud,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/estaciones/'),
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'ubicacion': ubicacion,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
      }),
    );
    if (response.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> editarEstacion({
    required int id,
    required String nombre,
    required String ubicacion,
    double? latitud,
    double? longitud,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/estaciones/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'ubicacion': ubicacion,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
      }),
    );
    if (response.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    return response.statusCode == 200;
  }

  Future<bool> eliminarEstacion(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/estaciones/$id'),
      headers: await _headers(),
    );
    if (response.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    return response.statusCode == 200;
  }

  // ── Lecturas ───────────────────────────────────────────────────────────────

  Future<List<Lectura>> fetchLecturas(int estacionId) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/estaciones/$estacionId/lecturas'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Lectura.fromJson(e)).toList();
    }
    if (response.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    throw Exception('Error al cargar lecturas');
  }

  Future<bool> registrarLectura({
    required int estacionId,
    required double temperatura,
    required double humedad,
    required double ph,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lecturas/'),
      headers: await _headers(),
      body: jsonEncode({
        'estacion_id': estacionId,
        'temperatura': temperatura,
        'humedad':     humedad,
        'ph':          ph,
        'valor':       (temperatura + humedad + ph) / 3,
      }),
    );
    if (response.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ── NUEVO: Riesgo por estación ─────────────────────────────────────────────

  /// Devuelve el nivel de riesgo actual: "NORMAL", "ALERTA", "PELIGRO" o "SIN DATOS"
  Future<String> fetchRiesgo(int estacionId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/estaciones/$estacionId/riesgo'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['nivel'] ?? 'SIN DATOS';
      }
      return 'SIN DATOS';
    } catch (_) {
      return 'SIN DATOS';
    }
  }
}
