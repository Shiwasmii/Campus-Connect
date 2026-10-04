import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/comentario.dart';
import '../models/evidencia.dart';
import '../models/seguimiento_solicitud.dart';
import '../models/solicitud.dart';

class SolicitudesException implements Exception {
  final String mensaje;
  final int? statusCode;

  const SolicitudesException(this.mensaje, {this.statusCode});

  @override
  String toString() => mensaje;
}

class SolicitudesService {
  final http.Client? _client;

  SolicitudesService({http.Client? client}) : _client = client;

  Future<List<Solicitud>> obtenerPorSolicitante(int solicitanteId) async {
    try {
      final response = await _get(
        ApiConfig.solicitudesPorSolicitante(solicitanteId),
      );

      if (response.statusCode != 200) {
        throw const SolicitudesException(
          'No se pudieron cargar las solicitudes.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const SolicitudesException('Respuesta inesperada del servidor.');
      }

      final solicitudes = decoded
          .whereType<Map>()
          .map((item) => Solicitud.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      solicitudes.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      return solicitudes;
    } on SolicitudesException {
      rethrow;
    } on SocketException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } on http.ClientException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } catch (_) {
      throw const SolicitudesException(
        'Ocurrió un error al consultar las solicitudes.',
      );
    }
  }

  Future<SeguimientoSolicitud> obtenerSeguimiento(int solicitudId) async {
    try {
      final response = await _get(ApiConfig.seguimientoUri(solicitudId));

      if (response.statusCode == 404) {
        throw const SolicitudesException(
          'La solicitud ya no existe.',
          statusCode: 404,
        );
      }

      if (response.statusCode != 200) {
        throw const SolicitudesException('No se pudo cargar el seguimiento.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const SolicitudesException('Respuesta inesperada del servidor.');
      }

      return SeguimientoSolicitud.fromJson(Map<String, dynamic>.from(decoded));
    } on SolicitudesException {
      rethrow;
    } on SocketException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } on http.ClientException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } catch (_) {
      throw const SolicitudesException(
        'Ocurrió un error al consultar el seguimiento.',
      );
    }
  }

  Future<Solicitud> crear({
    required String titulo,
    required String descripcion,
    required String categoria,
    required String prioridad,
    required int solicitanteId,
  }) async {
    try {
      final response = await _post(ApiConfig.crearSolicitudUri, {
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'categoria': categoria,
        'prioridad': prioridad,
        'solicitanteId': solicitanteId,
      });

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw const SolicitudesException(
            'Respuesta inesperada del servidor.',
          );
        }
        return Solicitud.fromJson(Map<String, dynamic>.from(decoded));
      }

      if (response.statusCode == 400) {
        throw SolicitudesException(_mensajeError(response.body));
      }

      throw const SolicitudesException('No se pudo crear la solicitud.');
    } on SolicitudesException {
      rethrow;
    } on SocketException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } on http.ClientException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } catch (_) {
      throw const SolicitudesException(
        'Ocurrió un error al crear la solicitud.',
      );
    }
  }

  Future<Comentario> agregarComentario({
    required int solicitudId,
    required int usuarioId,
    required String mensaje,
  }) async {
    try {
      final response = await _post(ApiConfig.comentarioUri(solicitudId), {
        'mensaje': mensaje.trim(),
        'usuarioId': usuarioId,
        'esInterno': false,
      });

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw const SolicitudesException(
            'Respuesta inesperada del servidor.',
          );
        }
        return Comentario.fromJson(Map<String, dynamic>.from(decoded));
      }

      if (response.statusCode == 400 || response.statusCode == 404) {
        throw SolicitudesException(
          _mensajeError(response.body),
          statusCode: response.statusCode,
        );
      }

      throw const SolicitudesException('No se pudo enviar el comentario.');
    } on SolicitudesException {
      rethrow;
    } on SocketException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } on http.ClientException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } catch (_) {
      throw const SolicitudesException(
        'Ocurrió un error al enviar el comentario.',
      );
    }
  }

  Future<Evidencia> adjuntarEvidencia({
    required int solicitudId,
    required int usuarioId,
    required XFile archivo,
  }) async {
    try {
      final bytes = await archivo.readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        ApiConfig.evidenciaUri(solicitudId),
      );
      request.headers['Accept'] = 'application/json';
      request.fields['subidoPorId'] = '$usuarioId';
      request.files.add(
        http.MultipartFile.fromBytes(
          'archivo',
          bytes,
          filename: _nombreArchivo(archivo),
          contentType: _tipoContenido(archivo),
        ),
      );

      final response = await http.Response.fromStream(await _send(request));
      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw const SolicitudesException(
            'Respuesta inesperada del servidor.',
          );
        }
        return Evidencia.fromJson(Map<String, dynamic>.from(decoded));
      }

      if (response.statusCode == 400 || response.statusCode == 404) {
        throw SolicitudesException(_mensajeError(response.body));
      }

      throw const SolicitudesException('No se pudo adjuntar la evidencia.');
    } on SolicitudesException {
      rethrow;
    } on SocketException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } on http.ClientException {
      throw const SolicitudesException(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } catch (_) {
      throw const SolicitudesException('No se pudo adjuntar la evidencia.');
    }
  }

  String _nombreArchivo(XFile archivo) {
    final nombre = archivo.name.trim();
    if (nombre.isEmpty || nombre == '.' || nombre == '/') {
      return 'evidencia.jpg';
    }
    return nombre;
  }

  http.MediaType _tipoContenido(XFile archivo) {
    final mime = archivo.mimeType;
    if (mime != null && mime.contains('/')) {
      final partes = mime.split('/');
      if (partes.length == 2 && partes[0].isNotEmpty && partes[1].isNotEmpty) {
        return http.MediaType(partes[0], partes[1]);
      }
    }
    return http.MediaType('image', 'jpeg');
  }

  String _mensajeError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final mensaje = decoded['mensaje'];
        if (mensaje is String && mensaje.trim().isNotEmpty) {
          return mensaje;
        }

        final errores = decoded['errors'];
        if (errores is Map) {
          final textos = <String>[];
          for (final valor in errores.values) {
            if (valor is List) {
              textos.addAll(valor.whereType<String>());
            } else if (valor is String && valor.trim().isNotEmpty) {
              textos.add(valor);
            }
          }
          if (textos.isNotEmpty) {
            return textos.join('\n');
          }
        }
      }
    } catch (_) {
      return 'No se pudo crear la solicitud. Revisa los datos e inténtalo de nuevo.';
    }
    return 'No se pudo crear la solicitud. Revisa los datos e inténtalo de nuevo.';
  }

  Future<http.Response> _get(Uri uri) {
    final headers = {'Accept': 'application/json'};
    final client = _client;
    if (client != null) {
      return client.get(uri, headers: headers);
    }
    return http.get(uri, headers: headers);
  }

  Future<http.Response> _post(Uri uri, Map<String, dynamic> body) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final encoded = jsonEncode(body);
    final client = _client;
    if (client != null) {
      return client.post(uri, headers: headers, body: encoded);
    }
    return http.post(uri, headers: headers, body: encoded);
  }

  Future<http.StreamedResponse> _send(http.BaseRequest request) {
    final client = _client;
    if (client != null) {
      return client.send(request);
    }
    return request.send();
  }
}
