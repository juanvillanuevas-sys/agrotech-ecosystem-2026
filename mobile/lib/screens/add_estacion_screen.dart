// lib/screens/add_estacion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'map_picker_screen.dart';

class AddEstacionScreen extends StatefulWidget {
  const AddEstacionScreen({super.key});

  @override
  State<AddEstacionScreen> createState() => _AddEstacionScreenState();
}

class _AddEstacionScreenState extends State<AddEstacionScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nombreCtrl   = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _latCtrl      = TextEditingController();
  final _lngCtrl      = TextEditingController();
  bool _isLoading     = false;
  LatLng? _coordenadas;
  final MapController _miniMapController = MapController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  // ── Abrir selector de mapa ─────────────────────────────────────────────────

  Future<void> _abrirMapa() async {
    final inicial = _coordenadas;
    final resultado = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(inicial: inicial),
      ),
    );
    if (resultado != null) {
      setState(() {
        _coordenadas = resultado;
        _latCtrl.text = resultado.latitude.toStringAsFixed(6);
        _lngCtrl.text = resultado.longitude.toStringAsFixed(6);
      });
      // Mover el mini-mapa a la nueva ubicación
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _miniMapController.move(_coordenadas!, 14.0);
      });
    }
  }

  // ── Guardar estación ───────────────────────────────────────────────────────

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final ok = await ApiService().crearEstacion(
        nombre:    _nombreCtrl.text.trim(),
        ubicacion: _ubicacionCtrl.text.trim(),
        latitud:   _latCtrl.text.isNotEmpty ? double.tryParse(_latCtrl.text) : null,
        longitud:  _lngCtrl.text.isNotEmpty ? double.tryParse(_lngCtrl.text) : null,
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

  // ── Build ──────────────────────────────────────────────────────────────────

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Nombre ──────────────────────────────────────────────────
              _campo(_nombreCtrl, 'Nombre', Icons.sensors,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),

              // ── Ubicación ────────────────────────────────────────────────
              _campo(_ubicacionCtrl, 'Ubicación', Icons.place,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 20),

              // ── Sección mapa ─────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.map_outlined, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Ubicación geográfica',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  const Text(
                    'Opcional',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Vista previa del mapa o botón para abrir ─────────────────
              if (_coordenadas != null) ...[
                // Mini-mapa con el pin seleccionado
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    child: FlutterMap(
                      mapController: _miniMapController,
                      options: MapOptions(
                        initialCenter: _coordenadas!,
                        initialZoom: 14.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.agrotech.smat',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _coordenadas!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Color(0xFFC62828),
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Botón cambiar ubicación
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _abrirMapa,
                    icon: const Icon(Icons.edit_location_alt,
                        color: Color(0xFF2E7D32)),
                    label: const Text('Cambiar ubicación',
                        style: TextStyle(color: Color(0xFF2E7D32))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else ...[
                // Botón seleccionar en mapa
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _abrirMapa,
                    icon: const Icon(Icons.add_location_alt,
                        color: Color(0xFF2E7D32)),
                    label: const Text('Seleccionar en el mapa',
                        style: TextStyle(color: Color(0xFF2E7D32))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Campos manuales de coordenadas ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _campo(_latCtrl, 'Latitud', Icons.my_location,
                        tipo: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        onChanged: (_) => _actualizarCoordenadas()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campo(_lngCtrl, 'Longitud', Icons.my_location,
                        tipo: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        onChanged: (_) => _actualizarCoordenadas()),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Puedes escribir las coordenadas manualmente o seleccionar en el mapa',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 28),

              // ── Botón guardar ────────────────────────────────────────────
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

  // Actualiza el pin del mini-mapa cuando se escriben coordenadas manualmente
  void _actualizarCoordenadas() {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat != null && lng != null &&
        lat >= -90 && lat <= 90 &&
        lng >= -180 && lng <= 180) {
      setState(() => _coordenadas = LatLng(lat, lng));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _miniMapController.move(_coordenadas!, 14.0);
      });
    }
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType tipo = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      onChanged: onChanged,
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
