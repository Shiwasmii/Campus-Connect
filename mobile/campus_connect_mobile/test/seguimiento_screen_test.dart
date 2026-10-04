import 'dart:async';

import 'package:campus_connect_mobile/models/comentario.dart';
import 'package:campus_connect_mobile/models/evidencia.dart';
import 'package:campus_connect_mobile/models/seguimiento_solicitud.dart';
import 'package:campus_connect_mobile/screens/seguimiento_screen.dart';
import 'package:campus_connect_mobile/services/solicitudes_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la carga del seguimiento', (tester) async {
    await tester.pumpWidget(
      _app(_ServicioPendiente()),
    );

    expect(find.text('Cargando seguimiento...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra el estado en proceso', (tester) async {
    await tester.pumpWidget(_app(_ServicioFijo(_base(estado: 'EnProceso'))));
    await tester.pumpAndSettle();

    expect(find.text('En proceso'), findsOneWidget);
    expect(find.text('TKT-202610-0001'), findsOneWidget);
    expect(find.text('Soporte tecnológico'), findsOneWidget);
  });

  testWidgets('indica cuando no hay responsable', (tester) async {
    await tester.pumpWidget(_app(_ServicioFijo(_base())));
    await tester.pumpAndSettle();

    expect(find.text('Responsable: Aún no asignado'), findsOneWidget);
  });

  testWidgets('muestra el responsable asignado', (tester) async {
    await tester.pumpWidget(
      _app(_ServicioFijo(_base(asignado: _persona('Laura Méndez')))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Responsable: Laura Méndez'), findsOneWidget);
  });

  testWidgets('muestra el comentario público y oculta el interno', (
    tester,
  ) async {
    final seguimiento = _base(
      comentarios: [
        _comentario(
          id: 1,
          mensaje: 'Nota interna del técnico',
          esInterno: true,
          fecha: DateTime.utc(2026, 10, 4, 12),
        ),
        _comentario(
          id: 2,
          mensaje: 'Ya revisamos el proyector',
          esInterno: false,
          nombre: 'Laura Méndez',
          rol: 'Tecnico',
          fecha: DateTime.utc(2026, 10, 4, 13),
        ),
      ],
    );

    await tester.pumpWidget(_app(_ServicioFijo(seguimiento)));
    await tester.pumpAndSettle();

    expect(find.text('Ya revisamos el proyector'), findsOneWidget);
    expect(find.text('Laura Méndez'), findsOneWidget);
    expect(find.text('Tecnico'), findsOneWidget);
    expect(find.text('Nota interna del técnico'), findsNothing);
  });

  testWidgets('muestra la evidencia adjunta', (tester) async {
    final seguimiento = _base(
      evidencias: [
        Evidencia(
          id: 3,
          nombreArchivoOriginal: 'aula.jpg',
          urlDescarga: '/uploads/evidencias/aula.jpg',
          contentType: 'image/jpeg',
          tamanoBytes: 2048,
          fechaSubida: DateTime.utc(2026, 10, 4, 15),
          subidoPorId: 15,
          subidoPorNombre: 'Ana Ruiz',
        ),
      ],
    );

    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_ServicioFijo(seguimiento)));
    await tester.pump();

    expect(find.text('aula.jpg'), findsOneWidget);
    expect(find.text('Subida por Ana Ruiz'), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);
  });

  testWidgets('muestra listas vacías', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_ServicioFijo(_base())));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay actualizaciones'), findsOneWidget);
    expect(find.text('Sin evidencias adjuntas'), findsOneWidget);
  });

  testWidgets('muestra el error de la API y permite reintentar', (tester) async {
    final servicio = _ServicioFijo(
      _base(),
      error: 'No se pudo conectar con el servidor.',
    );
    await tester.pumpWidget(_app(servicio));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('TKT-202610-0001'), findsNothing);

    servicio.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('TKT-202610-0001'), findsOneWidget);
  });

  testWidgets('un 404 indica que la solicitud ya no existe', (tester) async {
    await tester.pumpWidget(
      _app(_ServicioFijo(_base(), statusCode: 404)),
    );
    await tester.pumpAndSettle();

    expect(find.text('La solicitud ya no existe.'), findsOneWidget);
  });
}

Widget _app(SolicitudesService servicio) {
  return MaterialApp(
    home: SeguimientoScreen(
      solicitudId: 8,
      solicitudesService: servicio,
    ),
  );
}

class _ServicioPendiente extends SolicitudesService {
  final Completer<SeguimientoSolicitud> _completer =
      Completer<SeguimientoSolicitud>();

  @override
  Future<SeguimientoSolicitud> obtenerSeguimiento(int solicitudId) {
    return _completer.future;
  }
}

class _ServicioFijo extends SolicitudesService {
  final SeguimientoSolicitud seguimiento;
  String? error;
  final int? statusCode;
  final List<int> ids = [];

  _ServicioFijo(this.seguimiento, {this.error, this.statusCode});

  @override
  Future<SeguimientoSolicitud> obtenerSeguimiento(int solicitudId) async {
    ids.add(solicitudId);
    final mensaje = error;
    if (statusCode == 404) {
      throw const SolicitudesException(
        'La solicitud ya no existe.',
        statusCode: 404,
      );
    }
    if (mensaje != null) {
      throw SolicitudesException(mensaje);
    }
    return seguimiento;
  }
}

SeguimientoSolicitud _base({
  String estado = 'Pendiente',
  PersonaSeguimiento? asignado,
  List<Comentario> comentarios = const [],
  List<Evidencia> evidencias = const [],
}) {
  return SeguimientoSolicitud(
    id: 8,
    codigoTicket: 'TKT-202610-0001',
    titulo: 'Proyector del aula',
    descripcion: 'El proyector del aula 204 no enciende.',
    categoria: 'SoporteTecnologico',
    prioridad: 'Alta',
    estado: estado,
    fechaCreacion: DateTime.utc(2026, 10, 4, 10),
    fechaActualizacion: DateTime.utc(2026, 10, 4, 12),
    fechaCierre: null,
    solicitante: _persona('Ana Ruiz'),
    asignadoA: asignado,
    recurso: null,
    comentarios: comentarios,
    evidencias: evidencias,
  );
}

PersonaSeguimiento _persona(String nombre) {
  return PersonaSeguimiento(
    id: 2,
    nombreCompleto: nombre,
    correo: 'laura@universidad.edu',
    rol: 'Tecnico',
  );
}

Comentario _comentario({
  required int id,
  required String mensaje,
  required bool esInterno,
  required DateTime fecha,
  String nombre = 'Laura Méndez',
  String rol = 'Tecnico',
}) {
  return Comentario(
    id: id,
    mensaje: mensaje,
    fechaCreacion: fecha,
    esInterno: esInterno,
    usuarioId: 2,
    usuarioNombre: nombre,
    usuarioRol: rol,
  );
}
