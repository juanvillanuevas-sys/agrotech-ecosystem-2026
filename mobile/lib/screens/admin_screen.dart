import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/usuario.dart';

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminEstado();
}

class _PantallaAdminEstado extends State<PantallaAdmin> {
  final _api = ServicioApi();
  List<Usuario> _usuarios = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _api.obtenerUsuarios();
      setState(() {
        _usuarios = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('SIN_PERMISO')
            ? 'Tu cuenta no tiene permisos de administrador'
            : 'No se pudo cargar la lista de usuarios';
        _cargando = false;
      });
    }
  }

  Future<void> _cambiarRol(Usuario usuario, String nuevoRol) async {
    if (usuario.rol == nuevoRol) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cambio de rol'),
        content: Text(
          '¿Cambiar a "${usuario.username}" de ${usuario.rol.toUpperCase()} '
          'a ${nuevoRol.toUpperCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final exito = await _api.cambiarRolUsuario(usuario.id, nuevoRol);
      if (!mounted) return;
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol de ${usuario.username} actualizado')),
        );
        _cargarUsuarios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo cambiar el rol'),
              backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error al cambiar el rol'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Administración de Usuarios'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
          ),
        ],
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarUsuarios,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _usuarios.length,
        itemBuilder: (ctx, i) {
          final usuario = _usuarios[i];
          final esAdmin = usuario.rol == 'admin';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    esAdmin ? const Color(0xFF2E7D32) : Colors.grey[400],
                child: Icon(
                  esAdmin ? Icons.shield : Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                usuario.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(usuario.email),
              trailing: DropdownButton<String>(
                value: usuario.rol,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (nuevoRol) {
                  if (nuevoRol != null) _cambiarRol(usuario, nuevoRol);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
