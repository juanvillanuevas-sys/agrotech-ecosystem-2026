import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/estacion.dart';
import 'login_screen.dart';
import 'add_estacion_screen.dart';
import 'lecturas_screen.dart';
import 'mapa_estaciones_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = ApiService();
  List<Estacion> _estaciones = [];
  final Map<int, String> _riesgos = {}; // estacionId → nivel
  bool _isLoading = true;
  String? _error;
  String _rol = 'usuario';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _rol      = await AuthService().getRol();
    _username = await AuthService().getUsername();
    await _cargarEstaciones();
  }

  Future<void> _cargarEstaciones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final lista = await _api.fetchEstaciones();

      // Carga última lectura y nivel de riesgo de cada estación en paralelo
      final resultados = await Future.wait(
        lista.map((est) async {
          // Lecturas
          Estacion estConLectura = est;
          try {
            final lecturas = await _api.fetchLecturas(est.id);
            if (lecturas.isNotEmpty) {
              final ultima = lecturas.first;
              estConLectura = est.copyWith(
                ultimaTemperatura: ultima.temperatura,
                ultimaHumedad:     ultima.humedad,
              );
            }
          } catch (_) {}

          // Riesgo
          final nivel = await _api.fetchRiesgo(est.id);
          return MapEntry(estConLectura, nivel);
        }),
      );

      setState(() {
        _estaciones = resultados.map((e) => e.key).toList();
        _riesgos.clear();
        for (final r in resultados) {
          _riesgos[r.key.id] = r.value;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  Color _fondoNivel(String nivel) {
    switch (nivel) {
      case 'PELIGRO': return const Color(0xFFFFEBEE);
      case 'ALERTA':  return const Color(0xFFFFFDE7);
      case 'NORMAL':  return const Color(0xFFF1F8E9);
      default:        return Colors.white;
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

  // ── Diálogo editar ─────────────────────────────────────────────────────────

  void _mostrarEdicion(Estacion est) {
    final nombreCtrl = TextEditingController(text: est.nombre);
    final ubicCtrl   = TextEditingController(text: est.ubicacion);
    final latCtrl    = TextEditingController(text: est.latitud?.toString() ?? '');
    final lngCtrl    = TextEditingController(text: est.longitud?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Estación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nombreCtrl, 'Nombre'),
              const SizedBox(height: 10),
              _dialogField(ubicCtrl, 'Ubicación'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _dialogField(latCtrl, 'Latitud')),
                  const SizedBox(width: 8),
                  Expanded(child: _dialogField(lngCtrl, 'Longitud')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final ok = await _api.editarEstacion(
                id:        est.id,
                nombre:    nombreCtrl.text,
                ubicacion: ubicCtrl.text,
                latitud:   double.tryParse(latCtrl.text),
                longitud:  double.tryParse(lngCtrl.text),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                _cargarEstaciones();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error al guardar'),
                      backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  TextField _dialogField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  void _handleLogout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AgroTech',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Hola, $_username  •  ${_rol.toUpperCase()}',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.85))),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Ver mapa',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapaEstacionesScreen()),
            ).then((_) => _cargarEstaciones()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEstacionScreen()),
          );
          if (result == true) _cargarEstaciones();
        },
        backgroundColor: const Color(0xFF2E7D32),
        tooltip: 'Nueva estación',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Sin conexión con el servidor',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Verifica que el backend esté corriendo',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarEstaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_estaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sensors_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No hay estaciones registradas',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Toca + para crear la primera',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEstaciones,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _estaciones.length,
        itemBuilder: (ctx, i) {
          final est    = _estaciones[i];
          final nivel  = _riesgos[est.id] ?? 'SIN DATOS';
          final color  = _colorNivel(nivel);
          final fondo  = _fondoNivel(nivel);
          final icono  = _iconoNivel(nivel);

          return Dismissible(
            key: Key('est_${est.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _api.eliminarEstacion(est.id),
            onDismissed: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${est.nombre} eliminada')),
              );
              _cargarEstaciones();
            },
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              color: fondo,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => LecturasScreen(
                      estacion: est,
                      nivelRiesgo: nivel,
                    ),
                  ),
                ).then((_) => _cargarEstaciones()),
                onLongPress: () => _mostrarEdicion(est),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Fila superior: ícono sensor + nombre + badge nivel ──
                      Row(
                        children: [
                          Icon(Icons.sensors, color: color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  est.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'ID: ${est.id}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          // Badge de nivel
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
                                Icon(icono, size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  nivel,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Ubicación ──
                      Row(
                        children: [
                          const Icon(Icons.place, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              est.ubicacion,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                      // ── Coordenadas ──
                      if (est.latitud != null && est.longitud != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.my_location,
                                color: Colors.blueGrey, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${est.latitud!.toStringAsFixed(4)}, '
                              '${est.longitud!.toStringAsFixed(4)}',
                              style: const TextStyle(
                                  color: Colors.blueGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),

                      // ── Chips de última lectura ──
                      Row(
                        children: [
                          _chipLectura(
                            Icons.thermostat,
                            Colors.orange,
                            est.ultimaTemperatura != null
                                ? '${est.ultimaTemperatura!.toStringAsFixed(1)}°C'
                                : 'Sin datos',
                          ),
                          const SizedBox(width: 10),
                          _chipLectura(
                            Icons.water_drop,
                            Colors.blue,
                            est.ultimaHumedad != null
                                ? '${est.ultimaHumedad!.toStringAsFixed(1)}%'
                                : 'Sin datos',
                          ),
                          const Spacer(),
                          Text(
                            'Toca para ver historial',
                            style: TextStyle(color: color, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chipLectura(IconData icon, Color color, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 4),
          Text(texto,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
