import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddEstacionScreen extends StatefulWidget {
  const AddEstacionScreen({super.key});

  @override
  State<AddEstacionScreen> createState() => _AddEstacionScreenState();
}

class _AddEstacionScreenState extends State<AddEstacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  bool _isLoading = false;

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final ok = await ApiService().crearEstacion(
        nombre: _nombreCtrl.text.trim(),
        ubicacion: _ubicacionCtrl.text.trim(),
        latitud: _latCtrl.text.isNotEmpty
            ? double.tryParse(_latCtrl.text)
            : null,
        longitud: _lngCtrl.text.isNotEmpty
            ? double.tryParse(_lngCtrl.text)
            : null,
      );
      setState(() => _isLoading = false);

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        _mostrarError('No se pudo crear la estación');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError(e.toString().contains('TOKEN_EXPIRADO')
          ? 'Sesión expirada. Vuelve a iniciar sesión.'
          : 'Error de conexión con el servidor');
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Estación'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _campo(_nombreCtrl, 'Nombre', Icons.sensors,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              _campo(_ubicacionCtrl, 'Ubicación', Icons.place,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _campo(_latCtrl, 'Latitud', Icons.my_location,
                        tipo: TextInputType.numberWithOptions(decimal: true, signed: true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campo(_lngCtrl, 'Longitud', Icons.my_location,
                        tipo: TextInputType.numberWithOptions(decimal: true, signed: true)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Latitud y longitud son opcionales',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Estación',
                            style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType tipo = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}