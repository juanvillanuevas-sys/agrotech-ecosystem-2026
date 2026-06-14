import 'package:flutter/material.dart';
import '../models/estacion.dart';
import '../services/api_service.dart';

class PantallaAgregarLectura extends StatefulWidget {
  final Estacion estacion;
  const PantallaAgregarLectura({super.key, required this.estacion});

  @override
  State<PantallaAgregarLectura> createState() => _PantallaAgregarLecturaEstado();
}

class _PantallaAgregarLecturaEstado extends State<PantallaAgregarLectura> {
  final _claveFormulario = GlobalKey<FormState>();
  final _ctrlTemp        = TextEditingController();
  final _ctrlHum         = TextEditingController();
  final _ctrlPh          = TextEditingController();
  bool _cargando         = false;

  @override
  void dispose() {
    _ctrlTemp.dispose();
    _ctrlHum.dispose();
    _ctrlPh.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_claveFormulario.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final exito = await ServicioApi().registrarLectura(
        idEstacion:  widget.estacion.id,
        temperatura: double.parse(_ctrlTemp.text),
        humedad:     double.parse(_ctrlHum.text),
        ph:          double.parse(_ctrlPh.text),
      );
      setState(() => _cargando = false);
      if (!mounted) return;
      if (exito) {
        Navigator.pop(context, true);
      } else {
        _mostrarError('No se pudo registrar la lectura');
      }
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError(e.toString().contains('TOKEN_EXPIRADO')
          ? 'Sesión expirada. Vuelve a iniciar sesión.'
          : 'Error de conexión con el servidor');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
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
          key: _claveFormulario,
          child: Column(
            children: [
              // Temperatura
              TextFormField(
                controller: _ctrlTemp,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: 'Temperatura (°C)',
                  prefixIcon:
                      const Icon(Icons.thermostat, color: Colors.orange),
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

              // Humedad
              TextFormField(
                controller: _ctrlHum,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Humedad (%)',
                  prefixIcon:
                      const Icon(Icons.water_drop, color: Colors.blue),
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

              // pH
              TextFormField(
                controller: _ctrlPh,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'pH del suelo',
                  prefixIcon: const Icon(Icons.science,
                      color: Color(0xFF7B1FA2)),
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

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _cargando
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