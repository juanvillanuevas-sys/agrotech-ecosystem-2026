class Estacion {
  final int id;
  final String nombre;
  final String ubicacion;
  final double? latitud;
  final double? longitud;
  final int? propietarioId;
  final double? ultimaTemperatura;
  final double? ultimaHumedad;

  Estacion({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    this.latitud,
    this.longitud,
    this.propietarioId,
    this.ultimaTemperatura,
    this.ultimaHumedad,
  });

  factory Estacion.fromJson(Map<String, dynamic> json) {
    return Estacion(
      id:           json['id'],
      nombre:       json['nombre'],
      ubicacion:    json['ubicacion'],
      latitud:      (json['latitud']        as num?)?.toDouble(),
      longitud:     (json['longitud']       as num?)?.toDouble(),
      propietarioId: json['propietario_id'] as int?,
    );
  }

  Estacion copyWith({
    double? ultimaTemperatura,
    double? ultimaHumedad,
  }) {
    return Estacion(
      id:                 id,
      nombre:             nombre,
      ubicacion:          ubicacion,
      latitud:            latitud,
      longitud:           longitud,
      propietarioId:      propietarioId,
      ultimaTemperatura:  ultimaTemperatura ?? this.ultimaTemperatura,
      ultimaHumedad:      ultimaHumedad     ?? this.ultimaHumedad,
    );
  }
}