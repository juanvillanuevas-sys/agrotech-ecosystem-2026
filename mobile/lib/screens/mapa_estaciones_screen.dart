import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/estacion.dart';
import '../services/api_service.dart';
import 'lecturas_screen.dart';

class PantallaMapaEstaciones extends StatefulWidget {
  const PantallaMapaEstaciones({super.key});

  @override
  State<PantallaMapaEstaciones> createState() =>
      _PantallaMapaEstacionesEstado();
}

class _PantallaMapaEstacionesEstado extends State<PantallaMapaEstaciones> {
  final _api            = ServicioApi();
  final _controladorMapa = MapController();

  List<Estacion> _estaciones      = [];
  final Map<int, String> _riesgos = {};
  bool _cargando                  = true;
  String? _mensajeError;
  Estacion? _seleccionada;

  static const LatLng _centroInicial = LatLng(-12.0464, -77.0428);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
      _seleccionada = null;
    });
    try {
      final lista = await _api.obtenerEstaciones();

      final riesgos = await Future.wait(
        lista.map((e) async {
          final nivel = await _api.obtenerRiesgo(e.id);
          return MapEntry(e.id, nivel);
        }),
      );

      setState(() {
        _estaciones = lista;
        _riesgos.clear();
        for (final r in riesgos) {
          _riesgos[r.key] = r.value;
        }
        _cargando = false;
      });

      _centrarMapa();
    } catch (e) {
      setState(() { _mensajeError = e.toString(); _cargando = false; });
    }
  }

  void _centrarMapa() {
    final conCoordenadas = _estaciones
        .where((e) => e.latitud != null && e.longitud != null)
        .toList();
    if (conCoordenadas.isEmpty) return;

    if (conCoordenadas.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controladorMapa.move(
          LatLng(conCoordenadas.first.latitud!,
              conCoordenadas.first.longitud!),
          13.0,
        );
      });
      return;
    }

    final lats = conCoordenadas.map((e) => e.latitud!).toList();
    final lngs = conCoordenadas.map((e) => e.longitud!).toList();
    final latMin = lats.reduce((a, b) => a < b ? a : b);
    final latMax = lats.reduce((a, b) => a > b ? a : b);
    final lngMin = lngs.reduce((a, b) => a < b ? a : b);
    final lngMax = lngs.reduce((a, b) => a > b ? a : b);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controladorMapa.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(latMin - 0.02, lngMin - 0.02),
            LatLng(latMax + 0.02, lngMax + 0.02),
          ),
        ),
      );
    });
  }

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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _mensajeError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text('Error al cargar estaciones'),
                      TextButton(
                          onPressed: _cargar,
                          child: const Text('Reintentar')),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Mapa principal
                    FlutterMap(
                      mapController: _controladorMapa,
                      options: MapOptions(
                        initialCenter: _centroInicial,
                        initialZoom: 6.0,
                        onTap: (_, __) =>
                            setState(() => _seleccionada = null),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.agrotech.smat',
                        ),
                        MarkerLayer(
                          markers: conCoordenadas.map((est) {
                            final nivel =
                                _riesgos[est.id] ?? 'SIN DATOS';
                            final color = _colorNivel(nivel);
                            return Marker(
                              point: LatLng(est.latitud!, est.longitud!),
                              width: 48,
                              height: 56,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _seleccionada = est),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius:
                                            BorderRadius.circular(8),
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
                                    Icon(Icons.location_pin,
                                        color: color, size: 32),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Aviso estaciones sin coordenadas
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

                    // Contador
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2E7D32).withOpacity(0.9),
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

                    // Popup al tocar un pin
                    if (_seleccionada != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: _construirPopup(_seleccionada!),
                      ),
                  ],
                ),
    );
  }

  Widget _construirPopup(Estacion est) {
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
            Row(
              children: [
                Icon(Icons.sensors, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(est.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
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
                  child: const Icon(Icons.close,
                      color: Colors.grey, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, color: Colors.grey, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(est.ubicacion,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
            if (est.latitud != null && est.longitud != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.my_location,
                      color: Colors.blueGrey, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${est.latitud!.toStringAsFixed(4)}, '
                    '${est.longitud!.toStringAsFixed(4)}',
                    style: const TextStyle(
                        color: Colors.blueGrey, fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaLecturas(
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
