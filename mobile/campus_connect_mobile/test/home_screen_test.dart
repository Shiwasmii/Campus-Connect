import 'dart:async';

import 'package:campus_connect_mobile/models/seguimiento_solicitud.dart';
import 'package:campus_connect_mobile/models/solicitud.dart';
import 'package:campus_connect_mobile/models/usuario.dart';
import 'package:campus_connect_mobile/screens/home_screen.dart';
import 'package:campus_connect_mobile/services/solicitudes_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _usuario = Usuario(
  id: 15,
  nombreCompleto: 'Ana Ruiz',
  correo: 'ana.ruiz@universidad.edu',
  rol: 'Estudiante',
);

void main() {
  testWidgets('muestra el indicador de carga', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          usuario: _usuario,
          solicitudesService: _ServicioPendiente(),
        ),
      ),
    );

    expect(find.text('Cargando solicitudes...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra el estado vacío', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          usuario: _usuario,
          solicitudesService: _ServicioFijo(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todavía no tienes solicitudes.'), findsOneWidget);
    expect(find.text('Mis solicitudes'), findsOneWidget);
  });

  testWidgets('muestra una solicitud del usuario', (tester) async {
    final servicio = _ServicioFijo([_solicitudDePrueba()]);
    final idsConsultados = servicio.ids;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          usuario: _usuario,
          solicitudesService: servicio,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(idsConsultados, [15]);
    expect(find.text('TKT-202603-0001'), findsOneWidget);
    expect(find.text('Proyector de la sala 2'), findsOneWidget);
    expect(find.text('Soporte tecnológico'), findsOneWidget);
    expect(find.text('En proceso'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.textContaining('Responsable: Carlos Rivas'), findsOneWidget);

    await tester.tap(find.text('Proyector de la sala 2'));
    await tester.pumpAndSettle();

    expect(servicio.seguimientoConsultado, 4);
    expect(find.widgetWithText(AppBar, 'Seguimiento'), findsOneWidget);
    expect(find.text('TKT-202603-0001'), findsOneWidget);
    expect(find.text('En proceso'), findsOneWidget);
  });
}

class _ServicioPendiente extends SolicitudesService {
  final Completer<List<Solicitud>> _completer = Completer<List<Solicitud>>();

  @override
  Future<List<Solicitud>> obtenerPorSolicitante(int solicitanteId) {
    return _completer.future;
  }
}

class _ServicioFijo extends SolicitudesService {
  final List<Solicitud> solicitudes;
  final List<int> ids = [];
  int? seguimientoConsultado;

  _ServicioFijo(this.solicitudes);

  @override
  Future<List<Solicitud>> obtenerPorSolicitante(int solicitanteId) async {
    ids.add(solicitanteId);
    return solicitudes;
  }

  @override
  Future<SeguimientoSolicitud> obtenerSeguimiento(int solicitudId) async {
    seguimientoConsultado = solicitudId;
    final solicitud = solicitudes.firstWhere((s) => s.id == solicitudId);
    return SeguimientoSolicitud(
      id: solicitud.id,
      codigoTicket: solicitud.codigoTicket,
      titulo: solicitud.titulo,
      descripcion: solicitud.descripcion,
      categoria: solicitud.categoria,
      prioridad: solicitud.prioridad,
      estado: solicitud.estado,
      fechaCreacion: solicitud.fechaCreacion,
      fechaActualizacion: solicitud.fechaActualizacion,
      fechaCierre: null,
      solicitante: null,
      asignadoA: const PersonaSeguimiento(
        id: 2,
        nombreCompleto: 'Carlos Rivas',
        correo: 'carlos@universidad.edu',
        rol: 'Tecnico',
      ),
      recurso: null,
      comentarios: const [],
      evidencias: const [],
    );
  }
}

Solicitud _solicitudDePrueba() {
  return Solicitud(
    id: 4,
    codigoTicket: 'TKT-202603-0001',
    titulo: 'Proyector de la sala 2',
    descripcion: 'No enciende.',
    categoria: 'SoporteTecnologico',
    prioridad: 'Alta',
    estado: 'EnProceso',
    fechaCreacion: DateTime.utc(2026, 3, 2, 15, 30),
    fechaActualizacion: null,
    solicitanteId: 15,
    solicitanteNombre: 'Ana Ruiz',
    asignadoANombre: 'Carlos Rivas',
    recursoNombre: 'PRY-02 - Proyector',
  );
}
