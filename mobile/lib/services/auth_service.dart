import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Detecta automáticamente la plataforma para usar la URL correcta
  // Web (navegador)  → localhost:8000
  // Emulador Android → 10.0.2.2:8000
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000';
  }

  // ── Registro ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email':    email,
          'password': password,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      final body = jsonDecode(response.body);
      return {'success': false, 'error': body['detail'] ?? 'Error desconocido'};
    } catch (_) {
      return {'success': false, 'error': 'No se pudo conectar con el servidor'};
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        await prefs.setString('rol',       data['rol'] ?? 'usuario');
        await prefs.setString('username',  username);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<String> getRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol') ?? 'usuario';
  }

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('rol');
    await prefs.remove('username');
  }
}
