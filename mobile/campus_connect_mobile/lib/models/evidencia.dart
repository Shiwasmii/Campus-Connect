class Evidencia {
  final int id;
  final String nombreArchivoOriginal;
  final String urlDescarga;
  final String contentType;
  final int tamanoBytes;
  final DateTime fechaSubida;
  final int subidoPorId;
  final String subidoPorNombre;

  const Evidencia({
    required this.id,
    required this.nombreArchivoOriginal,
    required this.urlDescarga,
    required this.contentType,
    required this.tamanoBytes,
    required this.fechaSubida,
    required this.subidoPorId,
    required this.subidoPorNombre,
  });

  bool get esImagen {
    final tipo = contentType.toLowerCase();
    return tipo.startsWith('image/') && !tipo.contains('svg');
  }

  String get tamanoVisible {
    if (tamanoBytes < 1024) return '$tamanoBytes B';
    if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Evidencia.fromJson(Map<String, dynamic> json) {
    return Evidencia(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      nombreArchivoOriginal: json['nombreArchivoOriginal'] as String? ?? '',
      urlDescarga: json['urlDescarga'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      tamanoBytes: json['tamanoBytes'] is num
          ? (json['tamanoBytes'] as num).toInt()
          : 0,
      fechaSubida: json['fechaSubida'] is String
          ? DateTime.parse(json['fechaSubida'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      subidoPorId: json['subidoPorId'] is num
          ? (json['subidoPorId'] as num).toInt()
          : 0,
      subidoPorNombre: json['subidoPorNombre'] as String? ?? '',
    );
  }
}
