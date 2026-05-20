// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/estacion.dart';
import '../models/lectura.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const String _tokenKey = 'jwt_token';

  // ── Autenticación ──────────────────────────────────────────────────────────

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['access_token']);
      return true;
    }
    return false;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Estaciones ─────────────────────────────────────────────────────────────

  Future<List<Estacion>> getEstaciones() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/estaciones/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Estacion.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('no_autorizado');
    } else {
      throw Exception('Error al obtener estaciones');
    }
  }

  // ── NUEVO: Lecturas por estación ───────────────────────────────────────────

  Future<LecturaResumen> getLecturasEstacion(int estacionId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/estaciones/$estacionId/lecturas/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return LecturaResumen.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('no_autorizado');
    } else {
      throw Exception('Error al obtener lecturas');
    }
  }
}
