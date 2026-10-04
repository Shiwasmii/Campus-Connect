import 'dart:async';

import 'package:campus_connect_mobile/models/comentario.dart';
import 'package:campus_connect_mobile/models/seguimiento_solicitud.dart';
import 'package:campus_connect_mobile/models/usuario.dart';
import 'package:campus_connect_mobile/screens/seguimiento_screen.dart';
import 'package:campus_connect_mobile/services/solicitudes_service.dart';
import 'package:campus_connect_mobile/storage/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('un comentario vacío no se envía', (tester) async {
    final servicio = _Servicio();
    await tester.pumpWidget(_app(servicio));
    await tester.pumpAndSettle();

    await _pulsarEnviar(tester);

    expect(find.text('Escribe un comentario.'), findsOneWidget);
    expect(servicio.envios, 0);
  });

  testWidgets('un comentario con solo espacios no se envía', (tester) async {
    final servicio = _Servicio();
    await tester.pumpWidget(_app(servicio));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-comentario')), '   \n  ');
    await _pulsarEnviar(tester);

    expect(find.text('Escribe un comentario.'), findsOneWidget);
    expect(servicio.envios, 0);
  });

  testWidgets('envía el usuario de la sesión y refresca el seguimiento', (
    tester,
  ) async {
    final servicio = _Servicio();
    await tester.pumpWidget(_app(servicio, usuarioId: 27));
    await tester.pumpAndSettle();
    expect(servicio.consultas, 1);

    await tester.enterText(
      find.byKey(const Key('campo-comentario')),
      '  El problema sigue ocurriendo.  ',
    );
    await _pulsarEnviar(tester);
    await tester.pumpAndSettle();

    expect(servicio.envios, 1);
    expect(servicio.usuarioId, 27);
    expect(servicio.mensajeEnviado, 'El problema sigue ocurriendo.');
    expect(servicio.consultas, 2);
    expect(find.text('El problema sigue ocurriendo.'), findsOneWidget);
    expect(_textoDelCampo(tester), isEmpty);
  });

  testWidgets('si la API falla se conserva el texto', (tester) async {
    final servicio = _Servicio()
      ..errorEnvio = 'No se pudo enviar el comentario.';
    await tester.pumpWidget(_app(servicio, usuarioId: 27));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('campo-comentario')),
      'Sigue fallando',
    );
    await _pulsarEnviar(tester);
    await tester.pumpAndSettle();

    expect(servicio.envios, 1);
    expect(servicio.consultas, 1);
    expect(find.text('No se pudo enviar el comentario.'), findsOneWidget);
    expect(_textoDelCampo(tester), 'Sigue fallando');
  });

  testWidgets('no envía el comentario dos veces', (tester) async {
    final servicio = _Servicio()..espera = Completer<Comentario>();
    await tester.pumpWidget(_app(servicio, usuarioId: 27));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('campo-comentario')),
      'Un solo envío',
    );
    final boton = find.byKey(const Key('boton-enviar-comentario'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pump();

    expect(servicio.envios, 1);
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);

    await tester.tap(boton, warnIfMissed: false);
    await tester.pump();
    expect(servicio.envios, 1);

    servicio.espera!.complete(_comentario('Un solo envío'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(servicio.envios, 1);
    expect(servicio.consultas, 2);
  });
}

Widget _app(_Servicio servicio, {int usuarioId = 27}) {
  return MaterialApp(
    home: SeguimientoScreen(
      solicitudId: 8,
      solicitudesService: servicio,
      sessionStorage: _Sesion(usuarioId),
    ),
  );
}

Future<void> _pulsarEnviar(WidgetTester tester) async {
  final boton = find.byKey(const Key('boton-enviar-comentario'));
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pump();
}

String _textoDelCampo(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText)).controller.text;
}

class _Sesion extends SessionStorage {
  final int id;

  _Sesion(this.id);

  @override
  Future<Usuario?> obtenerUsuario() async {
    return Usuario(
      id: id,
      nombreCompleto: 'Ana Ruiz',
      correo: 'ana.ruiz@universidad.edu',
      rol: 'Estudiante',
    );
  }
}

class _Servicio extends SolicitudesService {
  int consultas = 0;
  int envios = 0;
  int? usuarioId;
  String? mensajeEnviado;
  String? errorEnvio;
  Completer<Comentario>? espera;
  String? publicado;

  @override
  Future<SeguimientoSolicitud> obtenerSeguimiento(int solicitudId) async {
    consultas++;
    final texto = publicado;
    return SeguimientoSolicitud(
      id: 8,
      codigoTicket: 'TKT-202610-0001',
      titulo: 'Proyector del aula',
      descripcion: 'No enciende.',
      categoria: 'SoporteTecnologico',
      prioridad: 'Alta',
      estado: 'Pendiente',
      fechaCreacion: DateTime.utc(2026, 10, 4, 10),
      fechaActualizacion: null,
      fechaCierre: null,
      solicitante: null,
      asignadoA: null,
      recurso: null,
      comentarios: texto == null ? const [] : [_comentario(texto)],
      evidencias: const [],
    );
  }

  @override
  Future<Comentario> agregarComentario({
    required int solicitudId,
    required int usuarioId,
    required String mensaje,
  }) async {
    envios++;
    this.usuarioId = usuarioId;
    mensajeEnviado = mensaje;
    final pendiente = espera;
    if (pendiente != null) {
      final creado = await pendiente.future;
      publicado = mensaje;
      return creado;
    }
    if (errorEnvio != null) {
      throw SolicitudesException(errorEnvio!);
    }
    publicado = mensaje;
    return _comentario(mensaje);
  }
}

Comentario _comentario(String mensaje) {
  return Comentario(
    id: 9,
    mensaje: mensaje,
    fechaCreacion: DateTime.utc(2026, 10, 4, 16),
    esInterno: false,
    usuarioId: 27,
    usuarioNombre: 'Ana Ruiz',
    usuarioRol: 'Estudiante',
  );
}
