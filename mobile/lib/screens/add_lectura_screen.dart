import 'package:flutter/material.dart';
import '../models/estacion.dart';
import '../services/api_service.dart';

class AddLecturaScreen extends StatefulWidget {
  final Estacion estacion;
  const AddLecturaScreen({super.key, required this.estacion});

  @override
  State<AddLecturaScreen> createState() => _AddLecturaScreenState();
}

class _AddLecturaScreenState extends State<AddLecturaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tempCtrl = TextEditingController();
  final _humCtrl  = TextEditingController();
  final _phCtrl   = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tempCtrl.dispose();
    _humCtrl.dispose();
    _phCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final ok = await ApiService().registrarLectura(
        estacionId:  widget.estacion.id,
        temperatura: double.parse(_tempCtrl.text),
        humedad:     double.parse(_humCtrl.text),
        ph:          double.parse(_phCtrl.text),
      );
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        _mostrarError('No se pudo registrar la lectura');
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
        title: Text('Lectura: ${widget.estacion.nombre}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // ── Temperatura ───────────────────────────────────────────────
              TextFormField(
                controller: _tempCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: 'Temperatura (°C)',
                  prefixIcon: const Icon(Icons.thermostat, color: Colors.orange),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Rango válido: -10 a 50 °C',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final d = double.tryParse(v);
                  if (d == null) return 'Número inválido';
                  if (d < -10 || d > 50) return 'Debe estar entre -10 y 50';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── Humedad ───────────────────────────────────────────────────
              TextFormField(
                controller: _humCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Humedad (%)',
                  prefixIcon: const Icon(Icons.water_drop, color: Colors.blue),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Rango válido: 0 a 100 %',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final d = double.tryParse(v);
                  if (d == null) return 'Número inválido';
                  if (d < 0 || d > 100) return 'Debe estar entre 0 y 100';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // ── pH ────────────────────────────────────────────────────────
              TextFormField(
                controller: _phCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'pH del suelo',
                  prefixIcon: const Icon(Icons.science, color: Color(0xFF7B1FA2)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Rango válido: 0 a 14',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final d = double.tryParse(v);
                  if (d == null) return 'Número inválido';
                  if (d < 0 || d > 14) return 'Debe estar entre 0 y 14';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── Botón guardar ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.upload),
                        label: const Text('Registrar Lectura',
                            style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF388E3C),
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
}
