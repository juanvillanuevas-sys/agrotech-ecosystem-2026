import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion.dart';
import '../models/lectura.dart';
import 'auth_service.dart';

class ServicioApi {
  final String urlBase = ServicioAutenticacion.urlBase;

  // ── Encabezados autorizados ────────────────────────────────────────────────

  Future<Map<String, String>> _encabezados() async {
    final token = await ServicioAutenticacion().obtenerToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Estaciones ─────────────────────────────────────────────────────────────

  Future<List<Estacion>> obtenerEstaciones() async {
    final respuesta = await http
        .get(Uri.parse('$urlBase/estaciones/'), headers: await _encabezados())
        .timeout(const Duration(seconds: 8));

    if (respuesta.statusCode == 200) {
      final List datos = json.decode(respuesta.body);
      return datos.map((e) => Estacion.fromJson(e)).toList();
    }
    if (respuesta.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    throw Exception('Error del servidor: ${respuesta.statusCode}');
  }

  Future<bool> crearEstacion({
    required String nombre,
    required String ubicacion,
    double? latitud,
    double? longitud,
  }) async {
    final respuesta = await http.post(
      Uri.parse('$urlBase/estaciones/'),
      headers: await _encabezados(),
      body: jsonEncode({
        'nombre':    nombre,
        'ubicacion': ubicacion,
        if (latitud  != null) 'latitud':  latitud,
        if (longitud != null) 'longitud': longitud,
      }),
    );
    if (respuesta.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    return respuesta.statusCode == 200 || respuesta.statusCode == 201;
  }

  Future<bool> editarEstacion({
    required int id,
    required String nombre,
    required String ubicacion,
    double? latitud,
    double? longitud,
  }) async {
    final respuesta = await http.put(
      Uri.parse('$urlBase/estaciones/$id'),
      headers: await _encabezados(),
      body: jsonEncode({
        'nombre':    nombre,
        'ubicacion': ubicacion,
        if (latitud  != null) 'latitud':  latitud,
        if (longitud != null) 'longitud': longitud,
      }),
    );
    if (respuesta.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    return respuesta.statusCode == 200;
  }

  Future<bool> eliminarEstacion(int id) async {
    final respuesta = await http.delete(
      Uri.parse('$urlBase/estaciones/$id'),
      headers: await _encabezados(),
    );
    if (respuesta.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    return respuesta.statusCode == 200;
  }

  // ── Lecturas ───────────────────────────────────────────────────────────────

  /// Usado por lecturas_screen y home_page
  Future<List<Lectura>> obtenerLecturas(int idEstacion) async {
    final respuesta = await http
        .get(
          Uri.parse('$urlBase/estaciones/$idEstacion/lecturas'),
          headers: await _encabezados(),
        )
        .timeout(const Duration(seconds: 8));

    if (respuesta.statusCode == 200) {
      final List datos = json.decode(respuesta.body);
      return datos.map((e) => Lectura.fromJson(e)).toList();
    }
    if (respuesta.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    throw Exception('Error al cargar lecturas');
  }

  /// Usado por detalle_screen — obtiene lecturas + nivel de riesgo en paralelo
  Future<LecturaResumen> obtenerLecturasResumen(int idEstacion) async {
    final resultados = await Future.wait([
      http
          .get(
            Uri.parse('$urlBase/estaciones/$idEstacion/lecturas'),
            headers: await _encabezados(),
          )
          .timeout(const Duration(seconds: 8)),
      http
          .get(
            Uri.parse('$urlBase/estaciones/$idEstacion/riesgo'),
            headers: await _encabezados(),
          )
          .timeout(const Duration(seconds: 8)),
    ]);

    List<Lectura> lecturas = [];
    if (resultados[0].statusCode == 200) {
      final List datos = json.decode(resultados[0].body);
      lecturas = datos.map((e) => Lectura.fromJson(e)).toList();
    }

    String nivel = 'SIN DATOS';
    if (resultados[1].statusCode == 200) {
      nivel = json.decode(resultados[1].body)['nivel'] ?? 'SIN DATOS';
    }

    // Solo las últimas 10 para el historial
    return LecturaResumen.fromLecturas(lecturas.take(10).toList(), nivel);
  }

  /// Usado por mapa_estaciones_screen y home_page
  Future<String> obtenerRiesgo(int idEstacion) async {
    try {
      final respuesta = await http
          .get(
            Uri.parse('$urlBase/estaciones/$idEstacion/riesgo'),
            headers: await _encabezados(),
          )
          .timeout(const Duration(seconds: 5));
      if (respuesta.statusCode == 200) {
        return json.decode(respuesta.body)['nivel'] ?? 'SIN DATOS';
      }
      return 'SIN DATOS';
    } catch (_) {
      return 'SIN DATOS';
    }
  }

  /// Usado por add_lectura_screen
  Future<bool> registrarLectura({
    required int idEstacion,
    required double temperatura,
    required double humedad,
    required double ph,
  }) async {
    final respuesta = await http.post(
      Uri.parse('$urlBase/lecturas/'),
      headers: await _encabezados(),
      body: jsonEncode({
        'estacion_id': idEstacion,
        'temperatura': temperatura,
        'humedad':     humedad,
        'ph':          ph,
        'valor':       (temperatura + humedad + ph) / 3,
      }),
    );
    if (respuesta.statusCode == 401) throw Exception('TOKEN_EXPIRADO');
    return respuesta.statusCode == 200 || respuesta.statusCode == 201;
  }
}