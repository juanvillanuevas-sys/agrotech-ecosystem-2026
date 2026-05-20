// lib/models/lectura.dart

class Lectura {
  final int id;
  final double humedad;
  final double temperatura;
  final double ph;
  final DateTime fecha;
  final int estacionId;

  Lectura({
    required this.id,
    required this.humedad,
    required this.temperatura,
    required this.ph,
    required this.fecha,
    required this.estacionId,
  });

  factory Lectura.fromJson(Map<String, dynamic> json) {
    return Lectura(
      id: json['id'],
      humedad: (json['humedad'] as num).toDouble(),
      temperatura: (json['temperatura'] as num).toDouble(),
      ph: (json['ph'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
      estacionId: json['estacion_id'],
    );
  }
}

class LecturaResumen {
  final int estacionId;
  final String estacionNombre;
  final String nivel;   // "NORMAL" | "ALERTA" | "PELIGRO" | "SIN_DATOS"
  final String mensaje;
  final List<Lectura> lecturas;

  LecturaResumen({
    required this.estacionId,
    required this.estacionNombre,
    required this.nivel,
    required this.mensaje,
    required this.lecturas,
  });

  factory LecturaResumen.fromJson(Map<String, dynamic> json) {
    return LecturaResumen(
      estacionId: json['estacion_id'],
      estacionNombre: json['estacion_nombre'],
      nivel: json['nivel'],
      mensaje: json['mensaje'],
      lecturas: (json['lecturas'] as List)
          .map((e) => Lectura.fromJson(e))
          .toList(),
    );
  }
}
