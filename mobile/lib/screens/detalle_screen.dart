// lib/screens/detalle_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/estacion.dart';
import '../models/lectura.dart';
import '../services/api_service.dart';

class DetalleScreen extends StatefulWidget {
  final Estacion estacion;
  final LecturaResumen? resumenInicial;

  const DetalleScreen({
    super.key,
    required this.estacion,
    this.resumenInicial,
  });

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  final _api = ApiService();
  LecturaResumen? _resumen;
  bool _cargando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resumen = widget.resumenInicial;
    _cargar();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _cargar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final r = await _api.getLecturasEstacion(widget.estacion.id);
      if (mounted) setState(() { _resumen = r; _cargando = false; });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Devuelve colores según nivel
  Color get _colorNivel {
    switch (_resumen?.nivel) {
      case 'PELIGRO': return const Color(0xFFC62828);
      case 'ALERTA':  return const Color(0xFFF9A825);
      case 'NORMAL':  return const Color(0xFF388E3C);
      default:        return Colors.grey;
    }
  }

  Color get _fondoNivel {
    switch (_resumen?.nivel) {
      case 'PELIGRO': return const Color(0xFFFFEBEE);
      case 'ALERTA':  return const Color(0xFFFFFDE7);
      case 'NORMAL':  return const Color(0xFFF1F8E9);
      default:        return const Color(0xFFF5F5F5);
    }
  }

  IconData get _iconoNivel {
    switch (_resumen?.nivel) {
      case 'PELIGRO': return Icons.warning_rounded;
      case 'ALERTA':  return Icons.error_outline_rounded;
      case 'NORMAL':  return Icons.check_circle_outline_rounded;
      default:        return Icons.sensors_off_outlined;
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
    final resumen = _resumen;
    final color = _colorNivel;
    final fondo = _fondoNivel;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(
          widget.estacion.nombre,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _cargar,
            ),
        ],
      ),
      body: resumen == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Banner de nivel ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: fondo,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(_iconoNivel, color: color, size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resumen.nivel,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                resumen.mensaje,
                                style: TextStyle(
                                    fontSize: 13, color: color.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Última lectura ───────────────────────────────────────
                  if (resumen.lecturas.isNotEmpty) ...[
                    const Text(
                      'Última lectura',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    _UltimaLecturaCard(
                      lectura: resumen.lecturas.first,
                      color: color,
                      fondo: fondo,
                    ),
                    const SizedBox(height: 20),

                    // ── Historial ────────────────────────────────────────
                    const Text(
                      'Historial (últimas 10 lecturas)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    ...resumen.lecturas.map(
                      (l) => _HistorialTile(
                        lectura: l,
                        formatFecha: _formatFecha,
                      ),
                    ),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.sensors_off_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Sin lecturas registradas.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ─── Tarjeta de última lectura con los 3 valores grandes ──────────────────────
class _UltimaLecturaCard extends StatelessWidget {
  final Lectura lectura;
  final Color color;
  final Color fondo;

  const _UltimaLecturaCard({
    required this.lectura,
    required this.color,
    required this.fondo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BigStat(
              icon: Icons.water_drop_outlined,
              label: 'Humedad',
              value: '${lectura.humedad.toStringAsFixed(1)}%',
              color: color,
            ),
            _BigStat(
              icon: Icons.thermostat_outlined,
              label: 'Temperatura',
              value: '${lectura.temperatura.toStringAsFixed(1)}°C',
              color: color,
            ),
            _BigStat(
              icon: Icons.science_outlined,
              label: 'pH',
              value: lectura.ph.toStringAsFixed(1),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BigStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// ─── Fila del historial ───────────────────────────────────────────────────────
class _HistorialTile extends StatelessWidget {
  final Lectura lectura;
  final String Function(DateTime) formatFecha;

  const _HistorialTile({required this.lectura, required this.formatFecha});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatFecha(lectura.fecha),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            _ChipDato(
                icon: Icons.water_drop_outlined,
                valor: '${lectura.humedad.toStringAsFixed(1)}%'),
            const SizedBox(width: 8),
            _ChipDato(
                icon: Icons.thermostat_outlined,
                valor: '${lectura.temperatura.toStringAsFixed(1)}°C'),
            const SizedBox(width: 8),
            _ChipDato(
                icon: Icons.science_outlined,
                valor: 'pH ${lectura.ph.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }
}

class _ChipDato extends StatelessWidget {
  final IconData icon;
  final String valor;

  const _ChipDato({required this.icon, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.blueGrey),
        const SizedBox(width: 3),
        Text(valor,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
      ],
    );
  }
}
