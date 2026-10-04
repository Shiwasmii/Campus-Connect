import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_connect_mobile/models/evidencia.dart';
import 'package:campus_connect_mobile/models/solicitud.dart';
import 'package:campus_connect_mobile/models/usuario.dart';
import 'package:campus_connect_mobile/screens/home_screen.dart';
import 'package:campus_connect_mobile/services/selector_imagen.dart';
import 'package:campus_connect_mobile/services/solicitudes_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

const _usuario = Usuario(
  id: 15,
  nombreCompleto: 'Ana Ruiz',
  correo: 'ana.ruiz@universidad.edu',
  rol: 'Estudiante',
);

void main() {
  testWidgets('exige los campos obligatorios', (tester) async {
    final servicio = _ServicioCreacion();
    await tester.pumpWidget(_app(servicio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    await _pulsarEnviar(tester);
    await tester.pump();

    expect(find.text('El título es obligatorio.'), findsOneWidget);
    expect(find.text('Selecciona una categoría.'), findsOneWidget);
    expect(find.text('Selecciona una prioridad.'), findsOneWidget);
    expect(find.text('La descripción es obligatoria.'), findsOneWidget);
    expect(servicio.creaciones, 0);
    expect(find.widgetWithText(AppBar, 'Nueva solicitud'), findsOneWidget);
  });

  testWidgets('crea la solicitud y refresca el inicio', (tester) async {
    final servicio = _ServicioCreacion();
    await tester.pumpWidget(_app(servicio));
    await tester.pumpAndSettle();
    expect(servicio.consultas, 1);

    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    await _completarFormulario(tester);
    await _pulsarEnviar(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(servicio.solicitanteId, 15);
    expect(servicio.categoria, 'SoporteTecnologico');
    expect(servicio.prioridad, 'Alta');
    expect(servicio.consultas, 2);
    expect(servicio.evidencias, 0);
    expect(
      find.text('Solicitud TKT-202610-0008 creada correctamente'),
      findsOneWidget,
    );
    expect(find.text('Luz del pasillo'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Campus Connect'), findsOneWidget);
    expect(find.byKey(const Key('campo-titulo')), findsNothing);
  });

  testWidgets('cancelar no recarga el listado', (tester) async {
    final servicio = _ServicioCreacion();
    await tester.pumpWidget(_app(servicio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    final cancelar = find.text('Cancelar');
    await tester.ensureVisible(cancelar);
    await tester.pumpAndSettle();
    await tester.tap(cancelar);
    await tester.pumpAndSettle();

    expect(servicio.consultas, 1);
    expect(servicio.creaciones, 0);
    expect(find.text('Todavía no tienes solicitudes.'), findsOneWidget);
  });

  testWidgets('un error del servidor mantiene el formulario', (tester) async {
    final servicio = _ServicioCreacion(
      error: 'El solicitante con ID 15 no existe o está inactivo.',
    );
    await tester.pumpWidget(_app(servicio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    await _completarFormulario(
      tester,
      titulo: 'Proyector del aula',
      descripcion: 'No enciende.',
    );
    await _pulsarEnviar(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('El solicitante con ID 15 no existe o está inactivo.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppBar, 'Nueva solicitud'), findsOneWidget);
    expect(find.text('Proyector del aula'), findsOneWidget);
    expect(find.text('No enciende.'), findsOneWidget);
    expect(servicio.consultas, 1);
  });

  testWidgets('crea la solicitud y adjunta la evidencia', (tester) async {
    final servicio = _ServicioCreacion();
    await tester.pumpWidget(
      _app(servicio, selector: _SelectorFijo(_archivoPequeno())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    await _completarFormulario(tester);
    await tester.tap(find.text('Elegir imagen'));
    await tester.pumpAndSettle();

    expect(find.text('aula.jpg'), findsOneWidget);
    await _pulsarEnviar(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(servicio.creaciones, 1);
    expect(servicio.evidencias, 1);
    expect(servicio.evidenciaSolicitudId, 8);
    expect(servicio.evidenciaUsuarioId, 15);
    expect(
      find.text('Solicitud TKT-202610-0008 creada correctamente'),
      findsOneWidget,
    );
  });

  testWidgets('si falla la evidencia no crea otra solicitud', (tester) async {
    final servicio = _ServicioCreacion(fallaEvidencia: true);
    await tester.pumpWidget(
      _app(servicio, selector: _SelectorFijo(_archivoPequeno())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    await _completarFormulario(tester);
    await tester.tap(find.text('Elegir imagen'));
    await tester.pumpAndSettle();
    await _pulsarEnviar(tester);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(servicio.creaciones, 1);
    expect(servicio.evidencias, 1);
    expect(servicio.evidenciaSolicitudId, 8);
    expect(servicio.evidenciaUsuarioId, 15);
    expect(
      find.text(
        'La solicitud fue creada correctamente, pero no se pudo adjuntar la evidencia.',
      ),
      findsOneWidget,
    );
    expect(find.text('Luz del pasillo'), findsOneWidget);
    expect(find.byKey(const Key('campo-titulo')), findsNothing);
  });

  testWidgets('rechaza un archivo mayor a 20 MB antes de enviarlo', (
    tester,
  ) async {
    final servicio = _ServicioCreacion();
    await tester.pumpWidget(
      _app(servicio, selector: _SelectorFijo(_archivoGrande())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    await _completarFormulario(tester);
    await tester.tap(find.text('Elegir imagen'));
    await tester.pumpAndSettle();
    await _pulsarEnviar(tester);
    await tester.pump();

    expect(
      find.text('El archivo excede el tamaño máximo permitido de 20 MB.'),
      findsOneWidget,
    );
    expect(servicio.creaciones, 0);
    expect(servicio.evidencias, 0);
    expect(find.widgetWithText(AppBar, 'Nueva solicitud'), findsOneWidget);
    expect(find.text('Luz del pasillo'), findsOneWidget);
  });
}

Widget _app(_ServicioCreacion servicio, {SelectorImagen? selector}) {
  return MaterialApp(
    home: HomeScreen(
      usuario: _usuario,
      solicitudesService: servicio,
      selectorImagen: selector,
    ),
  );
}

Future<void> _completarFormulario(
  WidgetTester tester, {
  String titulo = 'Luz del pasillo',
  String descripcion = 'La luz del segundo piso parpadea.',
}) async {
  await tester.enterText(find.byKey(const Key('campo-titulo')), titulo);
  await tester.enterText(
    find.byKey(const Key('campo-descripcion')),
    descripcion,
  );
  await _elegir(tester, const Key('campo-categoria'), 'Soporte tecnológico');
  await _elegir(tester, const Key('campo-prioridad'), 'Alta');
}

Future<void> _pulsarEnviar(WidgetTester tester) async {
  final boton = find.byKey(const Key('boton-enviar'));
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
}

Future<void> _elegir(WidgetTester tester, Key campo, String etiqueta) async {
  await tester.tap(find.byKey(campo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(etiqueta).last);
  await tester.pumpAndSettle();
}

class _SelectorFijo extends SelectorImagen {
  final XFile archivo;

  _SelectorFijo(this.archivo);

  @override
  Future<XFile?> elegirImagen() async => archivo;

  @override
  Future<XFile?> tomarFoto() async => archivo;
}

XFile _archivoPequeno() {
  return XFile.fromData(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ),
    path: 'aula.jpg',
    mimeType: 'image/jpeg',
  );
}

XFile _archivoGrande() {
  return XFile.fromData(
    Uint8List(0),
    path: 'grande.jpg',
    length: 21 * 1024 * 1024,
  );
}

class _ServicioCreacion extends SolicitudesService {
  final String? error;
  final bool fallaEvidencia;
  int consultas = 0;
  int creaciones = 0;
  int evidencias = 0;
  int? solicitanteId;
  String? categoria;
  String? prioridad;
  int? evidenciaSolicitudId;
  int? evidenciaUsuarioId;

  _ServicioCreacion({this.error, this.fallaEvidencia = false});

  @override
  Future<List<Solicitud>> obtenerPorSolicitante(int solicitanteId) async {
    consultas++;
    if (creaciones == 0) return const [];
    return [_solicitudCreada];
  }

  @override
  Future<Solicitud> crear({
    required String titulo,
    required String descripcion,
    required String categoria,
    required String prioridad,
    required int solicitanteId,
  }) async {
    creaciones++;
    this.solicitanteId = solicitanteId;
    this.categoria = categoria;
    this.prioridad = prioridad;
    if (error != null) {
      throw SolicitudesException(error!);
    }
    return _solicitudCreada;
  }

  @override
  Future<Evidencia> adjuntarEvidencia({
    required int solicitudId,
    required int usuarioId,
    required XFile archivo,
  }) async {
    evidencias++;
    evidenciaSolicitudId = solicitudId;
    evidenciaUsuarioId = usuarioId;
    if (fallaEvidencia) {
      throw const SolicitudesException('No se pudo adjuntar la evidencia.');
    }
    return Evidencia(
      id: 3,
      nombreArchivoOriginal: archivo.name,
      urlDescarga: '/uploads/evidencias/aula.jpg',
      contentType: 'image/jpeg',
      tamanoBytes: 4,
      fechaSubida: DateTime.utc(2026, 10, 4),
      subidoPorId: usuarioId,
      subidoPorNombre: 'Ana Ruiz',
    );
  }
}

final _solicitudCreada = Solicitud(
  id: 8,
  codigoTicket: 'TKT-202610-0008',
  titulo: 'Luz del pasillo',
  descripcion: 'La luz del segundo piso parpadea.',
  categoria: 'SoporteTecnologico',
  prioridad: 'Alta',
  estado: 'Pendiente',
  fechaCreacion: DateTime.utc(2026, 10, 4, 16),
  fechaActualizacion: null,
  solicitanteId: 15,
  solicitanteNombre: 'Ana Ruiz',
  asignadoANombre: null,
  recursoNombre: null,
);
