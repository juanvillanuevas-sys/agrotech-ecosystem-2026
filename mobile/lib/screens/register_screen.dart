import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroEstado();
}

class _PantallaRegistroEstado extends State<PantallaRegistro> {
  final _claveFormulario = GlobalKey<FormState>();
  final _ctrlUsuario     = TextEditingController();
  final _ctrlEmail       = TextEditingController();
  final _ctrlClave       = TextEditingController();
  final _ctrlConfirmar   = TextEditingController();
  bool _cargando         = false;
  bool _ocultarClave     = true;

  void _procesarRegistro() async {
    if (!_claveFormulario.currentState!.validate()) return;
    if (_ctrlClave.text != _ctrlConfirmar.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _cargando = true);
    final resultado = await ServicioAutenticacion().registrar(
      nombreUsuario: _ctrlUsuario.text.trim(),
      email:         _ctrlEmail.text.trim(),
      clave:         _ctrlClave.text,
    );
    setState(() => _cargando = false);
    if (!mounted) return;
    if (resultado['exito'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cuenta creada. Ahora inicia sesión.'),
            backgroundColor: Colors.green),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const PantallaLogin()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(resultado['error'] ?? 'Error al registrar'),
            backgroundColor: Colors.red),
      );
    }
  }

  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _claveFormulario,
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.person_add_alt_1,
                  size: 64, color: Color(0xFF2E7D32)),
              const SizedBox(height: 8),
              const Text('Únete a AgroTech',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20))),
              const SizedBox(height: 30),

              // Usuario
              TextFormField(
                controller: _ctrlUsuario,
                decoration: _decoracion('Usuario', Icons.person_outline),
                validator: (v) =>
                    v!.length < 3 ? 'Mínimo 3 caracteres' : null,
              ),
              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: _ctrlEmail,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    _decoracion('Correo electrónico', Icons.email_outlined),
                validator: (v) =>
                    v!.contains('@') ? null : 'Email inválido',
              ),
              const SizedBox(height: 14),

              // Contraseña
              TextFormField(
                controller: _ctrlClave,
                obscureText: _ocultarClave,
                decoration: _decoracion('Contraseña', Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarClave
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _ocultarClave = !_ocultarClave),
                  ),
                ),
                validator: (v) =>
                    v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 14),

              // Confirmar contraseña
              TextFormField(
                controller: _ctrlConfirmar,
                obscureText: _ocultarClave,
                decoration:
                    _decoracion('Confirmar contraseña', Icons.lock_outline),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _procesarRegistro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Registrarse',
                            style: TextStyle(fontSize: 16)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
