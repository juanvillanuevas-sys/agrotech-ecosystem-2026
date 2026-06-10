import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/estacion.dart';
import '../models/lectura.dart';
import '../services/api_service.dart';
import 'add_lectura_screen.dart';

class PantallaLecturas extends StatefulWidget {
  final Estacion estacion;
  final String nivelRiesgo;

  const PantallaLecturas({
    super.key,
    required this.estacion,
    this.nivelRiesgo = 'SIN DATOS',
  });

  @override
  State<PantallaLecturas> createState() => _PantallaLecturasEstado();
}

class _PantallaLecturasEstado extends State<PantallaLecturas> {
  List<Lectura> _lecturas = [];
  bool _cargando          = true;
  String? _mensajeError;
  late String _nivelRiesgo;

  bool _mostrarTemp = true;
  bool _mostrarHum  = true;
  bool _mostrarPh   = true;

  @override
  void initState() {
    super.initState();
    _nivelRiesgo = widget.nivelRiesgo;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _mensajeError = null; });
    try {
      final datos = await ServicioApi().obtenerLecturas(widget.estacion.id);
      final nivel = await ServicioApi().obtenerRiesgo(widget.estacion.id);
      setState(() { _lecturas = datos; _nivelRiesgo = nivel; _cargando = false; });
    } catch (e) {
      setState(() { _mensajeError = e.toString(); _cargando = false; });
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

  String _formatearFecha(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatearHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── Gráfica ────────────────────────────────────────────────────────────────

  Widget _construirGrafica() {
    final datos = _lecturas.reversed.toList();
    if (datos.isEmpty) return const SizedBox.shrink();

    List<FlSpot> puntosTemp = [];
    List<FlSpot> puntosHum  = [];
    List<FlSpot> puntosPh   = [];

    for (int i = 0; i < datos.length; i++) {
      final l = datos[i];
      if (l.temperatura != null) puntosTemp.add(FlSpot(i.toDouble(), l.temperatura!));
      if (l.humedad     != null) puntosHum.add(FlSpot(i.toDouble(), l.humedad!));
      if (l.ph          != null) puntosPh.add(FlSpot(i.toDouble(), l.ph! * 10));
    }

    final lineas = <LineChartBarData>[
      if (_mostrarTemp && puntosTemp.isNotEmpty)
        LineChartBarData(
          spots: puntosTemp,
          isCurved: true,
          color: Colors.orange,
          barWidth: 2.5,
          dotData: FlDotData(show: datos.length <= 10),
          belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.08)),
        ),
      if (_mostrarHum && puntosHum.isNotEmpty)
        LineChartBarData(
          spots: puntosHum,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2.5,
          dotData: FlDotData(show: datos.length <= 10),
          belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.08)),
        ),
      if (_mostrarPh && puntosPh.isNotEmpty)
        LineChartBarData(
          spots: puntosPh,
          isCurved: true,
          color: const Color(0xFF7B1FA2),
          barWidth: 2.5,
          dotData: FlDotData(show: datos.length <= 10),
          belowBarData: BarAreaData(show: true, color: const Color(0xFF7B1FA2).withOpacity(0.08)),
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Color(0xFF388E3C), size: 18),
                const SizedBox(width: 6),
                const Text('Tendencia',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                _botonToggle('Temp', Colors.orange, _mostrarTemp,
                    () => setState(() => _mostrarTemp = !_mostrarTemp)),
                const SizedBox(width: 6),
                _botonToggle('Hum', Colors.blue, _mostrarHum,
                    () => setState(() => _mostrarHum = !_mostrarHum)),
                const SizedBox(width: 6),
                _botonToggle('pH×10', const Color(0xFF7B1FA2), _mostrarPh,
                    () => setState(() => _mostrarPh = !_mostrarPh)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: lineas.isEmpty
                  ? const Center(
                      child: Text('Activa al menos una línea',
                          style: TextStyle(color: Colors.grey)))
                  : LineChart(
                      LineChartData(
                        lineBarsData: lineas,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: Colors.grey.withOpacity(0.15),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, _) => Text(
                                v.toStringAsFixed(0),
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.grey),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: datos.length <= 5
                                  ? 1
                                  : (datos.length / 5).ceilToDouble(),
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= datos.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  _formatearHora(datos[i].timestamp),
                                  style: const TextStyle(
                                      fontSize: 9, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (puntos) {
                              final etiquetas = ['Temp°C', 'Hum%', 'pH×10'];
                              final colores   = [
                                Colors.orange,
                                Colors.blue,
                                const Color(0xFF7B1FA2)
                              ];
                              return puntos.map((s) {
                                final idx = lineas.indexWhere((l) =>
                                    l.spots.any((p) => p.x == s.x && p.y == s.y));
                                return LineTooltipItem(
                                  '${idx >= 0 ? etiquetas[idx] : ''}: ${s.y.toStringAsFixed(1)}',
                                  TextStyle(
                                    color: idx >= 0 ? colores[idx] : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            const Text(
              '* pH se muestra ×10 para mejor visibilidad',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _botonToggle(
      String etiqueta, Color color, bool activo, VoidCallback alTocar) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: activo
              ? color.withOpacity(0.15)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: activo ? color : Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activo ? color : Colors.grey),
            ),
            const SizedBox(width: 4),
            Text(etiqueta,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: activo ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PantallaAgregarLectura(estacion: widget.estacion),
            ),
          );
          if (resultado == true) _cargar();
        },
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva lectura',
            style: TextStyle(color: Colors.white)),
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_mensajeError != null) {
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
          // Banner nivel
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
                      Text(_nivelRiesgo,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _colorNivel)),
                      const SizedBox(height: 2),
                      Text(_mensajeNivel,
                          style: TextStyle(
                              fontSize: 12,
                              color: _colorNivel.withOpacity(0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Gráfica
          if (_lecturas.isNotEmpty) _construirGrafica(),

          // Lista
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
                        style:
                            TextStyle(color: Colors.grey, fontSize: 16)),
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
                        Text(_formatearFecha(l.timestamp),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _chipDato(Icons.thermostat,
                                    Colors.orange,
                                    l.temperatura != null
                                        ? '${l.temperatura!.toStringAsFixed(1)}°C'
                                        : '-',
                                    'Temp.')),
                            Expanded(
                                child: _chipDato(Icons.water_drop,
                                    Colors.blue,
                                    l.humedad != null
                                        ? '${l.humedad!.toStringAsFixed(1)}%'
                                        : '-',
                                    'Humedad')),
                            Expanded(
                                child: _chipDato(Icons.science,
                                    const Color(0xFF7B1FA2),
                                    l.ph != null
                                        ? l.ph!.toStringAsFixed(1)
                                        : '-',
                                    'pH')),
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

  Widget _chipDato(
      IconData icono, Color color, String valor, String etiqueta) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(width: 4),
            Text(valor,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        Text(etiqueta,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
