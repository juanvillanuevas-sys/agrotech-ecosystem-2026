import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServicioAutenticacion {
  // Detecta automáticamente la plataforma para usar la URL correcta
  // Web (navegador)  → localhost:8000
  // Emulador Android → 10.0.2.2:8000
  static String get urlBase {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000';
  }

  // ── Registro ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> registrar({
    required String nombreUsuario,
    required String email,
    required String clave,
  }) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$urlBase/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': nombreUsuario,
          'email':    email,
          'password': clave,
        }),
      );
      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return {'exito': true};
      }
      final cuerpo = jsonDecode(respuesta.body);
      return {'exito': false, 'error': cuerpo['detail'] ?? 'Error desconocido'};
    } catch (_) {
      return {'exito': false, 'error': 'No se pudo conectar con el servidor'};
    }
  }

  // ── Inicio de sesión ───────────────────────────────────────────────────────

  Future<bool> iniciarSesion(String nombreUsuario, String clave) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$urlBase/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': nombreUsuario, 'password': clave},
      );
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        final preferencias = await SharedPreferences.getInstance();
        await preferencias.setString('jwt_token',      datos['access_token']);
        await preferencias.setString('rol',            datos['rol'] ?? 'usuario');
        await preferencias.setString('nombre_usuario', nombreUsuario);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<String?> obtenerToken() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString('jwt_token');
  }

  Future<String> obtenerRol() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString('rol') ?? 'usuario';
  }

  Future<String> obtenerUsuario() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString('nombre_usuario') ?? '';
  }

  Future<void> cerrarSesion() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove('jwt_token');
    await preferencias.remove('rol');
    await preferencias.remove('nombre_usuario');
  }
}