class Comentario {
  final int id;
  final String mensaje;
  final DateTime fechaCreacion;
  final bool esInterno;
  final int usuarioId;
  final String usuarioNombre;
  final String usuarioRol;

  const Comentario({
    required this.id,
    required this.mensaje,
    required this.fechaCreacion,
    required this.esInterno,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.usuarioRol,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      mensaje: json['mensaje'] as String? ?? '',
      fechaCreacion: json['fechaCreacion'] is String
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      esInterno: json['esInterno'] == true,
      usuarioId: json['usuarioId'] is num
          ? (json['usuarioId'] as num).toInt()
          : 0,
      usuarioNombre: json['usuarioNombre'] as String? ?? '',
      usuarioRol: json['usuarioRol'] as String? ?? '',
    );
  }
}
