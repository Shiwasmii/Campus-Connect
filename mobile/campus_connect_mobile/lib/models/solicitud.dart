class Solicitud {
  final int id;
  final String codigoTicket;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String prioridad;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final int solicitanteId;
  final String solicitanteNombre;
  final String? asignadoANombre;
  final String? recursoNombre;

  const Solicitud({
    required this.id,
    required this.codigoTicket,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.prioridad,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.solicitanteId,
    required this.solicitanteNombre,
    required this.asignadoANombre,
    required this.recursoNombre,
  });

  bool get tieneResponsable =>
      asignadoANombre != null && asignadoANombre!.trim().isNotEmpty;

  String get categoriaVisible {
    if (categoria == 'SoporteTecnologico') {
      return 'Soporte tecnológico';
    }
    return categoria;
  }

  String get fechaCreacionVisible => formatearFecha(fechaCreacion);

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: (json['id'] as num).toInt(),
      codigoTicket: json['codigoTicket'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String,
      prioridad: json['prioridad'] as String,
      estado: json['estado'] as String,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      fechaActualizacion: json['fechaActualizacion'] == null
          ? null
          : DateTime.parse(json['fechaActualizacion'] as String),
      solicitanteId: (json['solicitanteId'] as num).toInt(),
      solicitanteNombre: json['solicitanteNombre'] as String,
      asignadoANombre: json['asignadoANombre'] as String?,
      recursoNombre: json['recursoNombre'] as String?,
    );
  }
}

String formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year} $hora:$minuto';
}
