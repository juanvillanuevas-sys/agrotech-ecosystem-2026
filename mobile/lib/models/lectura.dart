class Lectura {
  final int id;
  final int idEstacion;
  final double? temperatura;
  final double? humedad;
  final double? ph;
  final DateTime timestamp;

  Lectura({
    required this.id,
    required this.idEstacion,
    this.temperatura,
    this.humedad,
    this.ph,
    required this.timestamp,
  });

  factory Lectura.fromJson(Map<String, dynamic> json) {
    return Lectura(
      id:          json['id'],
      idEstacion:  json['estacion_id'],
      temperatura: (json['temperatura'] as num?)?.toDouble(),
      humedad:     (json['humedad']     as num?)?.toDouble(),
      ph:          (json['ph']          as num?)?.toDouble(),
      timestamp:   DateTime.parse(json['timestamp']),
    );
  }
}

// ── LecturaResumen: usado por DetalleScreen ───────────────────────────────────
class LecturaResumen {
  final List<Lectura> lecturas;
  final String nivel;    // 'NORMAL' | 'ALERTA' | 'PELIGRO' | 'SIN DATOS'
  final String mensaje;

  LecturaResumen({
    required this.lecturas,
    required this.nivel,
    required this.mensaje,
  });

  static String _mensajePorNivel(String nivel) {
    switch (nivel) {
      case 'PELIGRO': return 'Condiciones críticas detectadas';
      case 'ALERTA':  return 'Valores fuera del rango normal';
      case 'NORMAL':  return 'Todos los parámetros en rango';
      default:        return 'Sin lecturas disponibles';
    }
  }

  factory LecturaResumen.fromLecturas(List<Lectura> lecturas, String nivel) {
    return LecturaResumen(
      lecturas: lecturas,
      nivel:    nivel,
      mensaje:  _mensajePorNivel(nivel),
    );
  }
}