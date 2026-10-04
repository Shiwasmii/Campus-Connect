import 'comentario.dart';
import 'evidencia.dart';

class PersonaSeguimiento {
  final int id;
  final String nombreCompleto;
  final String correo;
  final String rol;

  const PersonaSeguimiento({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.rol,
  });

  factory PersonaSeguimiento.fromJson(Map<String, dynamic> json) {
    return PersonaSeguimiento(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      nombreCompleto: json['nombreCompleto'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
    );
  }
}

class RecursoSeguimiento {
  final int id;
  final String codigo;
  final String nombre;
  final String tipo;
  final String ubicacion;
  final String estado;

  const RecursoSeguimiento({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.ubicacion,
    required this.estado,
  });

  String get visible {
    if (codigo.trim().isEmpty) return nombre;
    if (nombre.trim().isEmpty) return codigo;
    return '$codigo - $nombre';
  }

  factory RecursoSeguimiento.fromJson(Map<String, dynamic> json) {
    return RecursoSeguimiento(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      ubicacion: json['ubicacion'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
    );
  }
}

class SeguimientoSolicitud {
  final int id;
  final String codigoTicket;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String prioridad;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final DateTime? fechaCierre;
  final PersonaSeguimiento? solicitante;
  final PersonaSeguimiento? asignadoA;
  final RecursoSeguimiento? recurso;
  final List<Comentario> comentarios;
  final List<Evidencia> evidencias;

  const SeguimientoSolicitud({
    required this.id,
    required this.codigoTicket,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.prioridad,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.fechaCierre,
    required this.solicitante,
    required this.asignadoA,
    required this.recurso,
    required this.comentarios,
    required this.evidencias,
  });

  String get categoriaVisible {
    if (categoria == 'SoporteTecnologico') return 'Soporte tecnológico';
    return categoria;
  }

  String get responsableVisible {
    final nombre = asignadoA?.nombreCompleto.trim() ?? '';
    if (nombre.isEmpty) return 'Aún no asignado';
    return nombre;
  }

  bool get tieneResponsable => responsableVisible != 'Aún no asignado';

  List<Comentario> get comentariosPublicos {
    final publicos = comentarios.where((c) => !c.esInterno).toList();
    publicos.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    return publicos;
  }

  factory SeguimientoSolicitud.fromJson(Map<String, dynamic> json) {
    return SeguimientoSolicitud(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      codigoTicket: json['codigoTicket'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      prioridad: json['prioridad'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      fechaCreacion: json['fechaCreacion'] is String
          ? DateTime.parse(json['fechaCreacion'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      fechaActualizacion: json['fechaActualizacion'] is String
          ? DateTime.parse(json['fechaActualizacion'] as String)
          : null,
      fechaCierre: json['fechaCierre'] is String
          ? DateTime.parse(json['fechaCierre'] as String)
          : null,
      solicitante: json['solicitante'] is Map
          ? PersonaSeguimiento.fromJson(
              Map<String, dynamic>.from(json['solicitante'] as Map),
            )
          : null,
      asignadoA: json['asignadoA'] is Map
          ? PersonaSeguimiento.fromJson(
              Map<String, dynamic>.from(json['asignadoA'] as Map),
            )
          : null,
      recurso: json['recurso'] is Map
          ? RecursoSeguimiento.fromJson(
              Map<String, dynamic>.from(json['recurso'] as Map),
            )
          : null,
      comentarios: _lista(json['comentarios'], Comentario.fromJson),
      evidencias: _lista(json['evidencias'], Evidencia.fromJson),
    );
  }
}

List<T> _lista<T>(dynamic valor, T Function(Map<String, dynamic>) crear) {
  if (valor is! List) return [];
  return valor
      .whereType<Map>()
      .map((item) => crear(Map<String, dynamic>.from(item)))
      .toList();
}
