import 'dart:async';
import 'package:flutter/material.dart';
import '../models/estacion.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

class EstacionesScreen extends StatefulWidget {
  const EstacionesScreen({super.key});

  @override
  State<EstacionesScreen> createState() => _EstacionesScreenState();
}

class _EstacionesScreenState extends State<EstacionesScreen> {
  final _api = ApiService();
  List<Estacion> _estaciones = [];
  bool _cargando = true;
  String? _error;
  Timer? _timer;
  DateTime? _ultimaActualizacion;

  @override
  void initState() {
    super.initState();
    _cargarEstaciones();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cargarEstaciones(silencioso: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarEstaciones({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    setState(() => _error = null);

    try {
      final lista = await _api.getEstaciones();
      if (mounted) {
        setState(() {
          _estaciones = lista;
          _cargando = false;
          _ultimaActualizacion = DateTime.now();
        });
      }
    } on Exception catch (e) {
      if (!mounted) return;
      if (e.toString().contains('no_autorizado')) {
        await _api.logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        setState(() {
          _error = 'No se pudo cargar la información.';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cerrarSesion() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _formatHora(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Parcelas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarEstaciones,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_ultimaActualizacion != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFE8F5E9),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: Color(0xFF388E3C)),
                  const SizedBox(width: 6),
                  Text(
                    'Actualizado a las ${_formatHora(_ultimaActualizacion)}  •  Refresca cada 30 s',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF388E3C)),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarEstaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32)),
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
            Icon(Icons.grass, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hay estaciones registradas.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _cargarEstaciones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _estaciones.length,
        itemBuilder: (context, index) {
          final estacion = _estaciones[index];
          return _EstacionCard(estacion: estacion);
        },
      ),
    );
  }
}

class _EstacionCard extends StatelessWidget {
  final Estacion estacion;

  const _EstacionCard({required this.estacion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sensors, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estacion.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          estacion.ubicacion,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC8E6C9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ID ${estacion.id}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
