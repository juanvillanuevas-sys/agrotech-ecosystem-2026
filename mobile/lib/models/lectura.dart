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
