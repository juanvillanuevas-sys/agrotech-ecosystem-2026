import 'package:flutter/material.dart';
import '../models/estacion.dart';
import '../models/lectura.dart';
import '../services/api_service.dart';
import 'add_lectura_screen.dart';

class LecturasScreen extends StatefulWidget {
  final Estacion estacion;
  final String nivelRiesgo;

  const LecturasScreen({
    super.key,
    required this.estacion,
    this.nivelRiesgo = 'SIN DATOS',
  });

  @override
  State<LecturasScreen> createState() => _LecturasScreenState();
}

class _LecturasScreenState extends State<LecturasScreen> {
  List<Lectura> _lecturas = [];
  bool _isLoading = true;
  String? _error;
  late String _nivelRiesgo;

  @override
  void initState() {
    super.initState();
    _nivelRiesgo = widget.nivelRiesgo;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data  = await ApiService().fetchLecturas(widget.estacion.id);
      final nivel = await ApiService().fetchRiesgo(widget.estacion.id);
      setState(() {
        _lecturas    = data;
        _nivelRiesgo = nivel;
        _isLoading   = false;
      });
    } catch (e) {
      setState(() {
        _error     = e.toString();
        _isLoading = false;
      });
    }
  }

  Color get _colorNivel {
    switch (_nivelRiesgo) {
      case 'PELIGRO': return const Color(0xFFC62828);
      case 'ALERTA':  return const Color(0xFFF9A825);
      case 'NORMAL':  return const Color(0xFF388E3C);
      default:        return Colors.grey;
    }
  }

  Color get _fondoNivel {
    switch (_nivelRiesgo) {
      case 'PELIGRO': return const Color(0xFFFFEBEE);
      case 'ALERTA':  return const Color(0xFFFFFDE7);
      case 'NORMAL':  return const Color(0xFFF1F8E9);
      default:        return const Color(0xFFF5F5F5);
    }
  }

  IconData get _iconoNivel {
    switch (_nivelRiesgo) {
      case 'PELIGRO': return Icons.warning_rounded;
      case 'ALERTA':  return Icons.error_outline_rounded;
      case 'NORMAL':  return Icons.check_circle_outline_rounded;
      default:        return Icons.sensors_off_outlined;
    }
  }

  String get _mensajeNivel {
    switch (_nivelRiesgo) {
      case 'PELIGRO': return 'Riesgo crítico. Revisar de inmediato.';
      case 'ALERTA':  return 'Fuera del rango óptimo. Monitorear.';
      case 'NORMAL':  return 'Condiciones óptimas para el cultivo.';
      default:        return 'Sin lecturas registradas aún.';
    }
  }

  String _formatFecha(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.estacion.nombre,
                style: const TextStyle(fontSize: 16)),
            Text('Historial de lecturas',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.8))),
          ],
        ),
        backgroundColor: _colorNivel,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddLecturaScreen(estacion: widget.estacion),
            ),
          );
          if (result == true) _cargar();
        },
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva lectura',
            style: TextStyle(color: Colors.white)),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Error al cargar lecturas'),
            TextButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── Banner de nivel de riesgo ──────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _fondoNivel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _colorNivel.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(_iconoNivel, color: _colorNivel, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nivelRiesgo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _colorNivel,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _mensajeNivel,
                        style: TextStyle(
                            fontSize: 12,
                            color: _colorNivel.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Lista de lecturas ──────────────────────────────────────────
          if (_lecturas.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.sensors_off,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('Sin lecturas aún',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            ...(_lecturas.map((l) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatFecha(l.timestamp),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _chipLectura(
                                Icons.thermostat, Colors.orange,
                                l.temperatura != null
                                    ? '${l.temperatura!.toStringAsFixed(1)}°C'
                                    : '-',
                                'Temp.',
                              ),
                            ),
                            Expanded(
                              child: _chipLectura(
                                Icons.water_drop, Colors.blue,
                                l.humedad != null
                                    ? '${l.humedad!.toStringAsFixed(1)}%'
                                    : '-',
                                'Humedad',
                              ),
                            ),
                            Expanded(
                              child: _chipLectura(
                                Icons.science,
                                const Color(0xFF7B1FA2),
                                l.ph != null
                                    ? l.ph!.toStringAsFixed(1)
                                    : '-',
                                'pH',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ))),
        ],
      ),
    );
  }

  Widget _chipLectura(IconData icon, Color color, String valor, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(valor,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
