import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_connect_mobile/config/api_config.dart';
import 'package:campus_connect_mobile/services/solicitudes_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('consulta el solicitante de la sesión y ordena por fecha', () async {
    late Uri uriConsultada;
    final client = MockClient((request) async {
      uriConsultada = request.url;
      return http.Response(
        jsonEncode([
          _json(
            id: 1,
            codigo: 'TKT-ANTIGUA',
            fecha: '2026-01-01T10:00:00Z',
          ),
          _json(
            id: 2,
            codigo: 'TKT-RECIENTE',
            fecha: '2026-03-02T15:30:00Z',
            asignado: 'Laura Méndez',
          ),
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final solicitudes = await SolicitudesService(
      client: client,
    ).obtenerPorSolicitante(15);

    expect(uriConsultada.path, '/api/SolicitudesApi');
    expect(uriConsultada.queryParameters['solicitanteId'], '15');
    expect(solicitudes.map((s) => s.codigoTicket), [
      'TKT-RECIENTE',
      'TKT-ANTIGUA',
    ]);
    expect(solicitudes.first.categoriaVisible, 'Soporte tecnológico');
    expect(solicitudes.first.asignadoANombre, 'Laura Méndez');
    expect(solicitudes.last.asignadoANombre, isNull);
  });

  test('interpreta una respuesta real con campos nulos omitidos', () async {
    const cuerpo = '''
[
  {
    "id": 1,
    "codigoTicket": "TKT-202610-0001",
    "titulo": "Proyector del aula no funciona",
    "descripcion": "El proyector del aula 204 no enciende correctamente.",
    "categoria": "SoporteTecnologico",
    "prioridad": "Alta",
    "estado": "Pendiente",
    "fechaCreacion": "2026-10-04T04:46:14.300175",
    "solicitanteId": 1,
    "solicitanteNombre": "Juan Pérez (Estudiante)"
  }
]
''';
    final client = MockClient((request) async => http.Response(cuerpo, 200));

    final solicitudes = await SolicitudesService(
      client: client,
    ).obtenerPorSolicitante(1);

    expect(solicitudes, hasLength(1));
    expect(solicitudes.single.codigoTicket, 'TKT-202610-0001');
    expect(solicitudes.single.categoriaVisible, 'Soporte tecnológico');
    expect(solicitudes.single.tieneResponsable, isFalse);
    expect(solicitudes.single.fechaActualizacion, isNull);
  });

  test('envía solo los campos que acepta la API', () async {
    late Map<String, dynamic> body;
    late String metodo;
    final client = MockClient((request) async {
      metodo = request.method;
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'id': 9,
          'codigoTicket': 'TKT-202610-0002',
          'titulo': body['titulo'],
          'descripcion': body['descripcion'],
          'categoria': 'SoporteTecnologico',
          'prioridad': 'Alta',
          'estado': 'Pendiente',
          'fechaCreacion': '2026-10-04T16:00:00Z',
          'solicitanteId': 15,
          'solicitanteNombre': 'Ana Ruiz',
        }),
        201,
      );
    });

    final creada = await SolicitudesService(client: client).crear(
      titulo: ' Proyector ',
      descripcion: ' No enciende ',
      categoria: 'SoporteTecnologico',
      prioridad: 'Alta',
      solicitanteId: 15,
    );

    expect(metodo, 'POST');
    expect(body['titulo'], 'Proyector');
    expect(body['descripcion'], 'No enciende');
    expect(body['categoria'], 'SoporteTecnologico');
    expect(body['prioridad'], 'Alta');
    expect(body['solicitanteId'], 15);
    expect(body.containsKey('codigoTicket'), isFalse);
    expect(body.containsKey('estado'), isFalse);
    expect(body.containsKey('fechaCreacion'), isFalse);
    expect(creada.codigoTicket, 'TKT-202610-0002');
  });

  test('adjunta la evidencia a la solicitud recién creada', () async {
    final archivo = XFile.fromData(
      Uint8List.fromList([9, 8, 7]),
      path: 'aula.jpg',
      mimeType: 'image/jpeg',
    );
    late Uri uri;
    late String cuerpo;
    late String? tipo;
    final client = MockClient((request) async {
      uri = request.url;
      tipo = request.headers['content-type'];
      cuerpo = request.body;
      return http.Response(
        jsonEncode({
          'id': 4,
          'nombreArchivoOriginal': 'aula.jpg',
          'urlDescarga': '/uploads/evidencias/aula.jpg',
          'contentType': 'image/jpeg',
          'tamanoBytes': 3,
          'fechaSubida': '2026-10-04T16:00:00Z',
          'subidoPorId': 15,
          'subidoPorNombre': 'Ana Ruiz',
        }),
        201,
      );
    });

    final evidencia = await SolicitudesService(client: client).adjuntarEvidencia(
      solicitudId: 8,
      usuarioId: 15,
      archivo: archivo,
    );

    expect(uri.path, '/api/SolicitudesApi/8/evidencias');
    expect(tipo, contains('multipart/form-data'));
    expect(cuerpo, contains('name="subidoPorId"'));
    expect(cuerpo, contains('15'));
    expect(cuerpo, contains('name="archivo"'));
    expect(cuerpo, contains('filename="aula.jpg"'));
    expect(evidencia.subidoPorId, 15);
    expect(evidencia.nombreArchivoOriginal, 'aula.jpg');
  });

  test('consulta el seguimiento y conserva campos opcionales nulos', () async {
    late Uri uri;
    final client = MockClient((request) async {
      uri = request.url;
      return http.Response(
        jsonEncode({
          'id': 8,
          'codigoTicket': 'TKT-202610-0003',
          'titulo': 'Puerta del laboratorio',
          'descripcion': 'No cierra.',
          'categoria': 'Infraestructura',
          'prioridad': 'Media',
          'estado': 'Pendiente',
          'fechaCreacion': '2026-10-04T10:00:00Z',
          'solicitante': {
            'id': 1,
            'nombreCompleto': 'Juan Pérez',
            'correo': 'juan.perez@universidad.edu',
            'rol': 'Estudiante',
          },
          'comentarios': [
            {
              'id': 1,
              'mensaje': 'Nota interna',
              'fechaCreacion': '2026-10-04T11:00:00Z',
              'esInterno': true,
              'usuarioId': 2,
              'usuarioNombre': 'Laura',
              'usuarioRol': 'Tecnico',
            },
          ],
          'evidencias': [
            {
              'id': 5,
              'nombreArchivoOriginal': 'puerta.jpg',
              'urlDescarga': '/uploads/evidencias/puerta.jpg',
              'contentType': 'image/jpeg',
              'tamanoBytes': 1024,
              'fechaSubida': '2026-10-04T11:30:00Z',
              'subidoPorId': 1,
              'subidoPorNombre': 'Juan Pérez',
            },
          ],
        }),
        200,
      );
    });

    final seguimiento = await SolicitudesService(
      client: client,
    ).obtenerSeguimiento(8);

    expect(uri.path, '/api/SolicitudesApi/8/seguimiento');
    expect(seguimiento.asignadoA, isNull);
    expect(seguimiento.recurso, isNull);
    expect(seguimiento.fechaActualizacion, isNull);
    expect(seguimiento.comentarios.single.esInterno, isTrue);
    expect(seguimiento.comentariosPublicos, isEmpty);
    expect(
      ApiConfig.resolverUrl(seguimiento.evidencias.single.urlDescarga),
      'http://127.0.0.1:5274/uploads/evidencias/puerta.jpg',
    );
  });

  test('envía el comentario como público con el usuario indicado', () async {
    late Map<String, dynamic> body;
    late Uri uri;
    final client = MockClient((request) async {
      uri = request.url;
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'id': 9,
          'mensaje': body['mensaje'],
          'fechaCreacion': '2026-10-04T16:00:00Z',
          'esInterno': false,
          'usuarioId': 27,
          'usuarioNombre': 'Ana Ruiz',
          'usuarioRol': 'Estudiante',
        }),
        201,
      );
    });

    final comentario = await SolicitudesService(client: client).agregarComentario(
      solicitudId: 8,
      usuarioId: 27,
      mensaje: '  El problema sigue ocurriendo.  ',
    );

    expect(uri.path, '/api/SolicitudesApi/8/comentarios');
    expect(body['mensaje'], 'El problema sigue ocurriendo.');
    expect(body['usuarioId'], 27);
    expect(body['esInterno'], isFalse);
    expect(body.containsKey('esInterno'), isTrue);
    expect(comentario.esInterno, isFalse);
  });

  test('una lista vacía no es un error', () async {
    final client = MockClient((request) async {
      return http.Response('[]', 200);
    });

    final solicitudes = await SolicitudesService(
      client: client,
    ).obtenerPorSolicitante(3);

    expect(solicitudes, isEmpty);
  });
}

Map<String, dynamic> _json({
  required int id,
  required String codigo,
  required String fecha,
  String? asignado,
}) {
  return {
    'id': id,
    'codigoTicket': codigo,
    'titulo': 'Solicitud $id',
    'descripcion': 'Detalle',
    'categoria': 'SoporteTecnologico',
    'prioridad': 'Media',
    'estado': 'Pendiente',
    'fechaCreacion': fecha,
    'fechaActualizacion': null,
    'solicitanteId': 15,
    'solicitanteNombre': 'Ana Ruiz',
    'asignadoANombre': asignado,
    'recursoNombre': null,
  };
}
