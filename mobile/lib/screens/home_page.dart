import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/estacion.dart';
import 'login_screen.dart';
import 'add_estacion_screen.dart';
import 'lecturas_screen.dart';
import 'mapa_estaciones_screen.dart';

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalEstado();
}

class _PaginaPrincipalEstado extends State<PaginaPrincipal> {
  final _api = ServicioApi();
  List<Estacion> _estaciones          = [];
  final Map<int, String> _riesgos     = {};
  bool _cargando                      = true;
  String? _mensajeError;
  String _rol                         = 'usuario';
  String _nombreUsuario               = '';

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    _rol          = await ServicioAutenticacion().obtenerRol();
    _nombreUsuario = await ServicioAutenticacion().obtenerUsuario();
    await _cargarEstaciones();
  }

  Future<void> _cargarEstaciones() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });
    try {
      final lista = await _api.obtenerEstaciones();

      final resultados = await Future.wait(
        lista.map((est) async {
          // Última lectura
          Estacion estConLectura = est;
          try {
            final lecturas = await _api.obtenerLecturas(est.id);
            if (lecturas.isNotEmpty) {
              final ultima = lecturas.first;
              estConLectura = est.copyWith(
                ultimaTemperatura: ultima.temperatura,
                ultimaHumedad:     ultima.humedad,
              );
            }
          } catch (_) {}

          // Nivel de riesgo
          final nivel = await _api.obtenerRiesgo(est.id);
          return MapEntry(estConLectura, nivel);
        }),
      );

      setState(() {
        _estaciones = resultados.map((e) => e.key).toList();
        _riesgos.clear();
        for (final r in resultados) {
          _riesgos[r.key.id] = r.value;
        }
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _mensajeError = e.toString();
        _cargando = false;
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
    final ctrlNombre   = TextEditingController(text: est.nombre);
    final ctrlUbicacion = TextEditingController(text: est.ubicacion);
    final ctrlLatitud  = TextEditingController(text: est.latitud?.toString() ?? '');
    final ctrlLongitud = TextEditingController(text: est.longitud?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Estación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campoDialogo(ctrlNombre, 'Nombre'),
              const SizedBox(height: 10),
              _campoDialogo(ctrlUbicacion, 'Ubicación'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _campoDialogo(ctrlLatitud, 'Latitud')),
                  const SizedBox(width: 8),
                  Expanded(child: _campoDialogo(ctrlLongitud, 'Longitud')),
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
              final exito = await _api.editarEstacion(
                id:        est.id,
                nombre:    ctrlNombre.text,
                ubicacion: ctrlUbicacion.text,
                latitud:   double.tryParse(ctrlLatitud.text),
                longitud:  double.tryParse(ctrlLongitud.text),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (exito) {
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

  TextField _campoDialogo(TextEditingController ctrl, String etiqueta) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  void _cerrarSesion() async {
    await ServicioAutenticacion().cerrarSesion();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PantallaLogin()),
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
            Text('Hola, $_nombreUsuario  •  ${_rol.toUpperCase()}',
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
              MaterialPageRoute(
                  builder: (_) => const PantallaMapaEstaciones()),
            ).then((_) => _cargarEstaciones()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PantallaAgregarEstacion()),
          );
          if (resultado == true) _cargarEstaciones();
        },
        backgroundColor: const Color(0xFF2E7D32),
        tooltip: 'Nueva estación',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_mensajeError != null) {
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hay estaciones registradas',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Toca + para crear la primera',
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
          final est   = _estaciones[i];
          final nivel = _riesgos[est.id] ?? 'SIN DATOS';
          final color = _colorNivel(nivel);
          final fondo = _fondoNivel(nivel);
          final icono = _iconoNivel(nivel);

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
                    builder: (_) => PantallaLecturas(
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
                      // Fila superior: ícono + nombre + ID + badge nivel
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
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

                      // Ubicación
                      Row(
                        children: [
                          const Icon(Icons.place,
                              color: Colors.grey, size: 14),
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

                      // Coordenadas
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

                      // Chips de última lectura
                      Row(
                        children: [
                          _chipDato(
                            Icons.thermostat,
                            Colors.orange,
                            est.ultimaTemperatura != null
                                ? '${est.ultimaTemperatura!.toStringAsFixed(1)}°C'
                                : 'Sin datos',
                          ),
                          const SizedBox(width: 10),
                          _chipDato(
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

  Widget _chipDato(IconData icono, Color color, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 15),
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