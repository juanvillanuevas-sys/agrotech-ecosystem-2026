// lib/screens/mapa_estaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/estacion.dart';
import '../services/api_service.dart';
import 'lecturas_screen.dart';

class MapaEstacionesScreen extends StatefulWidget {
  const MapaEstacionesScreen({super.key});

  @override
  State<MapaEstacionesScreen> createState() => _MapaEstacionesScreenState();
}

class _MapaEstacionesScreenState extends State<MapaEstacionesScreen> {
  final _api          = ApiService();
  final _mapController = MapController();

  List<Estacion> _estaciones       = [];
  final Map<int, String> _riesgos  = {};
  bool _isLoading                  = true;
  String? _error;

  // Estación seleccionada para el popup
  Estacion? _seleccionada;

  // Lima como centro por defecto
  static const LatLng _defaultCenter = LatLng(-12.0464, -77.0428);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _isLoading = true; _error = null; _seleccionada = null; });
    try {
      final lista = await _api.fetchEstaciones();

      final riesgos = await Future.wait(
        lista.map((e) async {
          final nivel = await _api.fetchRiesgo(e.id);
          return MapEntry(e.id, nivel);
        }),
      );

      setState(() {
        _estaciones = lista;
        _riesgos.clear();
        for (final r in riesgos) {
          _riesgos[r.key] = r.value;
        }
        _isLoading = false;
      });

      // Centrar mapa en todas las estaciones con coordenadas
      _centrarMapa();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _centrarMapa() {
    final conCoordenadas = _estaciones
        .where((e) => e.latitud != null && e.longitud != null)
        .toList();
    if (conCoordenadas.isEmpty) return;

    if (conCoordenadas.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(conCoordenadas.first.latitud!, conCoordenadas.first.longitud!),
          13.0,
        );
      });
      return;
    }

    // Calcular bounds para mostrar todas las estaciones
    final lats = conCoordenadas.map((e) => e.latitud!).toList();
    final lngs = conCoordenadas.map((e) => e.longitud!).toList();
    final latMin = lats.reduce((a, b) => a < b ? a : b);
    final latMax = lats.reduce((a, b) => a > b ? a : b);
    final lngMin = lngs.reduce((a, b) => a < b ? a : b);
    final lngMax = lngs.reduce((a, b) => a > b ? a : b);
    final centro = LatLng((latMin + latMax) / 2, (lngMin + lngMax) / 2);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(latMin - 0.02, lngMin - 0.02),
            LatLng(latMax + 0.02, lngMax + 0.02),
          ),
        ),
      );
    });
  }

  // ── Colores según nivel ────────────────────────────────────────────────────

  Color _colorNivel(String nivel) {
    switch (nivel) {
      case 'PELIGRO': return const Color(0xFFC62828);
      case 'ALERTA':  return const Color(0xFFF9A825);
      case 'NORMAL':  return const Color(0xFF388E3C);
      default:        return Colors.grey;
    }
  }

  IconData _iconoNivel(String nivel) {
    switch (nivel) {
      case 'PELIGRO': return Icons.warning_rounded;
      case 'ALERTA':  return Icons.error_outline_rounded;
      case 'NORMAL':  return Icons.check_circle_outline_rounded;
      default:        return Icons.sensors_off_outlined;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final conCoordenadas = _estaciones
        .where((e) => e.latitud != null && e.longitud != null)
        .toList();
    final sinCoordenadas = _estaciones.length - conCoordenadas.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Estaciones'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text('Error al cargar estaciones'),
                      TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // ── Mapa principal ───────────────────────────────────────
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _defaultCenter,
                        initialZoom: 6.0,
                        onTap: (_, __) => setState(() => _seleccionada = null),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.agrotech.smat',
                        ),
                        MarkerLayer(
                          markers: conCoordenadas.map((est) {
                            final nivel = _riesgos[est.id] ?? 'SIN DATOS';
                            final color = _colorNivel(nivel);
                            return Marker(
                              point: LatLng(est.latitud!, est.longitud!),
                              width: 48,
                              height: 56,
                              child: GestureDetector(
                                onTap: () => setState(() => _seleccionada = est),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Etiqueta con nombre
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        est.nombre,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Pin
                                    Icon(Icons.location_pin, color: color, size: 32),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // ── Aviso estaciones sin coordenadas ─────────────────────
                    if (sinCoordenadas > 0)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '$sinCoordenadas estación${sinCoordenadas > 1 ? 'es' : ''} sin ubicación',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Contador de estaciones ────────────────────────────────
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sensors,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${conCoordenadas.length} en mapa',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Popup al tocar un pin ─────────────────────────────────
                    if (_seleccionada != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: _buildPopup(_seleccionada!),
                      ),
                  ],
                ),
    );
  }

  Widget _buildPopup(Estacion est) {
    final nivel = _riesgos[est.id] ?? 'SIN DATOS';
    final color = _colorNivel(nivel);
    final icono = _iconoNivel(nivel);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nombre + badge nivel + cerrar
            Row(
              children: [
                Icon(Icons.sensors, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    est.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icono, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(nivel,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _seleccionada = null),
                  child: const Icon(Icons.close, color: Colors.grey, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Ubicación
            Row(
              children: [
                const Icon(Icons.place, color: Colors.grey, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(est.ubicacion,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),

            // Coordenadas
            if (est.latitud != null && est.longitud != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.blueGrey, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${est.latitud!.toStringAsFixed(4)}, ${est.longitud!.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Botón ver historial
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LecturasScreen(
                        estacion: est,
                        nivelRiesgo: nivel,
                      ),
                    ),
                  ).then((_) => _cargar());
                },
                icon: const Icon(Icons.bar_chart, size: 16),
                label: const Text('Ver historial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
