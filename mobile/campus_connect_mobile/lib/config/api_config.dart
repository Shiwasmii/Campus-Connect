import 'dart:io';

/// Dirección del backend local según la plataforma.
///
/// El emulador de Android ve la máquina anfitriona en 10.0.2.2.
/// El simulador de iOS y la app de macOS usan 127.0.0.1.
class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5274';
    }
    return 'http://127.0.0.1:5274';
  }

  static Uri get loginUri => Uri.parse('$baseUrl/api/AuthApi/login');

  static Uri get crearSolicitudUri => Uri.parse('$baseUrl/api/SolicitudesApi');

  static Uri evidenciaUri(int solicitudId) {
    return Uri.parse('$baseUrl/api/SolicitudesApi/$solicitudId/evidencias');
  }

  static Uri seguimientoUri(int solicitudId) {
    return Uri.parse('$baseUrl/api/SolicitudesApi/$solicitudId/seguimiento');
  }

  static Uri comentarioUri(int solicitudId) {
    return Uri.parse('$baseUrl/api/SolicitudesApi/$solicitudId/comentarios');
  }

  /// Convierte una ruta relativa del backend en una URL absoluta.
  static String resolverUrl(String ruta) {
    final limpia = ruta.trim();
    if (limpia.isEmpty) return '';
    if (limpia.startsWith('http://') || limpia.startsWith('https://')) {
      return limpia;
    }
    if (limpia.startsWith('/')) return '$baseUrl$limpia';
    return '$baseUrl/$limpia';
  }

  static Uri solicitudesPorSolicitante(int solicitanteId) {
    return Uri.parse(
      '$baseUrl/api/SolicitudesApi',
    ).replace(queryParameters: {'solicitanteId': '$solicitanteId'});
  }
}
