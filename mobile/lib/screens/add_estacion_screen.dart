import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'map_picker_screen.dart';

class PantallaAgregarEstacion extends StatefulWidget {
  const PantallaAgregarEstacion({super.key});

  @override
  State<PantallaAgregarEstacion> createState() =>
      _PantallaAgregarEstacionEstado();
}

class _PantallaAgregarEstacionEstado
    extends State<PantallaAgregarEstacion> {
  final _claveFormulario  = GlobalKey<FormState>();
  final _ctrlNombre       = TextEditingController();
  final _ctrlUbicacion    = TextEditingController();
  final _ctrlLatitud      = TextEditingController();
  final _ctrlLongitud     = TextEditingController();
  bool _cargando          = false;
  LatLng? _coordenadas;
  final MapController _controladorMiniMapa = MapController();

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlUbicacion.dispose();
    _ctrlLatitud.dispose();
    _ctrlLongitud.dispose();
    super.dispose();
  }

  // ── Abrir selector de mapa ─────────────────────────────────────────────────

  Future<void> _abrirMapa() async {
    final coordenadasActuales = _coordenadas;
    final resultado = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PantallaSeleccionarUbicacion(inicial: coordenadasActuales),
      ),
    );
    if (resultado != null) {
      setState(() {
        _coordenadas = resultado;
        _ctrlLatitud.text  = resultado.latitude.toStringAsFixed(6);
        _ctrlLongitud.text = resultado.longitude.toStringAsFixed(6);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controladorMiniMapa.move(_coordenadas!, 14.0);
      });
    }
  }

  // ── Guardar estación ───────────────────────────────────────────────────────

  void _guardar() async {
    if (!_claveFormulario.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final exito = await ServicioApi().crearEstacion(
        nombre:    _ctrlNombre.text.trim(),
        ubicacion: _ctrlUbicacion.text.trim(),
        latitud:   _ctrlLatitud.text.isNotEmpty
            ? double.tryParse(_ctrlLatitud.text)
            : null,
        longitud:  _ctrlLongitud.text.isNotEmpty
            ? double.tryParse(_ctrlLongitud.text)
            : null,
      );
      setState(() => _cargando = false);
      if (!mounted) return;
      if (exito) {
        Navigator.pop(context, true);
      } else {
        _mostrarError('No se pudo crear la estación');
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

  void _actualizarCoordenadas() {
    final lat = double.tryParse(_ctrlLatitud.text);
    final lng = double.tryParse(_ctrlLongitud.text);
    if (lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180) {
      setState(() => _coordenadas = LatLng(lat, lng));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controladorMiniMapa.move(_coordenadas!, 14.0);
      });
    }
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
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              _campo(_ctrlNombre, 'Nombre', Icons.sensors,
                  validador: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),

              // Ubicación
              _campo(_ctrlUbicacion, 'Ubicación', Icons.place,
                  validador: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 20),

              // Sección mapa
              Row(
                children: [
                  const Icon(Icons.map_outlined,
                      color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Ubicación geográfica',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  const Text('Opcional',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),

              // Vista previa del mapa o botón para abrir
              if (_coordenadas != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    child: FlutterMap(
                      mapController: _controladorMiniMapa,
                      options: MapOptions(
                        initialCenter: _coordenadas!,
                        initialZoom: 14.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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

              // Campos manuales de coordenadas
              Row(
                children: [
                  Expanded(
                    child: _campo(_ctrlLatitud, 'Latitud', Icons.my_location,
                        tipo: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        alCambiar: (_) => _actualizarCoordenadas()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campo(_ctrlLongitud, 'Longitud', Icons.my_location,
                        tipo: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        alCambiar: (_) => _actualizarCoordenadas()),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Puedes escribir las coordenadas manualmente o seleccionar en el mapa',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 28),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _cargando
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
    String etiqueta,
    IconData icono, {
    String? Function(String?)? validador,
    TextInputType tipo = TextInputType.text,
    void Function(String)? alCambiar,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      onChanged: alCambiar,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validador,
    );
  }
}