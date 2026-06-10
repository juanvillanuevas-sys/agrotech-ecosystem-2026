// lib/screens/map_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Pantalla reutilizable para seleccionar una ubicación en el mapa.
/// Retorna un [LatLng] con las coordenadas seleccionadas al hacer pop.
///
/// Uso:
/// ```dart
/// final resultado = await Navigator.push<LatLng>(
///   context,
///   MaterialPageRoute(builder: (_) => MapPickerScreen(inicial: LatLng(-12.0, -77.0))),
/// );
/// if (resultado != null) { ... }
/// ```
class MapPickerScreen extends StatefulWidget {
  final LatLng? inicial;

  const MapPickerScreen({super.key, this.inicial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Lima, Perú como centro por defecto
  static const LatLng _defaultCenter = LatLng(-12.0464, -77.0428);

  late LatLng _seleccionado;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _seleccionado = widget.inicial ?? _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,

      ),
      body: Stack(
        children: [
          // ── Mapa ────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _seleccionado,
              initialZoom: 13.0,
              onTap: (tapPosition, punto) {
                setState(() => _seleccionado = punto);
              },
            ),
            children: [
              // Capa de tiles OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.agrotech.smat',
              ),
              // Pin de la ubicación seleccionada
              MarkerLayer(
                markers: [
                  Marker(
                    point: _seleccionado,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFC62828),
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Coordenadas en pantalla ──────────────────────────────────────
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lat: ${_seleccionado.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Lng: ${_seleccionado.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _seleccionado),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ),
          ),

          // ── Instrucción al centro ────────────────────────────────────────
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Toca el mapa para seleccionar la ubicación',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
