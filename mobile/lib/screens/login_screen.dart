import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_screen.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginEstado();
}

class _PantallaLoginEstado extends State<PantallaLogin> {
  final _ctrlUsuario = TextEditingController();
  final _ctrlClave   = TextEditingController();
  bool _cargando     = false;
  bool _ocultarClave = true;

  void _procesarLogin() async {
    if (_ctrlUsuario.text.isEmpty || _ctrlClave.text.isEmpty) return;
    setState(() => _cargando = true);
    final exito = await ServicioAutenticacion()
        .iniciarSesion(_ctrlUsuario.text.trim(), _ctrlClave.text);
    setState(() => _cargando = false);
    if (!mounted) return;
    if (exito) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaginaPrincipal()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales incorrectas o servidor offline'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.eco, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'AgroTech',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const Text(
                  'Monitoreo de estaciones agrícolas',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Campo usuario
                TextField(
                  controller: _ctrlUsuario,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Campo contraseña
                TextField(
                  controller: _ctrlClave,
                  obscureText: _ocultarClave,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarClave
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _ocultarClave = !_ocultarClave),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _procesarLogin(),
                ),
                const SizedBox(height: 28),

                // Botón iniciar sesión
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _procesarLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Iniciar Sesión',
                              style: TextStyle(fontSize: 16)),
                        ),
                ),
                const SizedBox(height: 20),

                // Link a registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes cuenta? '),
                    GestureDetector(
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PantallaRegistro()),
                      ),
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
