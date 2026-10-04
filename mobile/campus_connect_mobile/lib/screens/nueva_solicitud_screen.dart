import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/selector_imagen.dart';
import '../services/solicitudes_service.dart';
import '../widgets/app_section.dart';

class ResultadoNuevaSolicitud {
  final String codigoTicket;
  final bool evidenciaFallida;

  const ResultadoNuevaSolicitud({
    required this.codigoTicket,
    required this.evidenciaFallida,
  });

  String get mensaje {
    if (evidenciaFallida) {
      return 'La solicitud fue creada correctamente, pero no se pudo adjuntar la evidencia.';
    }
    return 'Solicitud $codigoTicket creada correctamente';
  }
}

class _Opcion {
  final String valor;
  final String etiqueta;

  const _Opcion(this.valor, this.etiqueta);
}

const _categorias = [
  _Opcion('Mantenimiento', 'Mantenimiento'),
  _Opcion('SoporteTecnologico', 'Soporte tecnológico'),
  _Opcion('Infraestructura', 'Infraestructura'),
];

const _prioridades = [
  _Opcion('Baja', 'Baja'),
  _Opcion('Media', 'Media'),
  _Opcion('Alta', 'Alta'),
  _Opcion('Urgente', 'Urgente'),
];

const tamanoMaximoEvidencia = 20 * 1024 * 1024;

class NuevaSolicitudScreen extends StatefulWidget {
  final int solicitanteId;
  final SolicitudesService solicitudesService;
  final SelectorImagen selectorImagen;

  NuevaSolicitudScreen({
    super.key,
    required this.solicitanteId,
    SolicitudesService? solicitudesService,
    SelectorImagen? selectorImagen,
  }) : solicitudesService = solicitudesService ?? SolicitudesService(),
       selectorImagen = selectorImagen ?? SelectorImagen();

  @override
  State<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends State<NuevaSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  String? _categoria;
  String? _prioridad;
  XFile? _archivo;
  Uint8List? _vistaPrevia;
  bool _enviando = false;
  String? _errorApi;

  /// Ticket ya creado. Evita un segundo POST si la evidencia falla.
  int? _solicitudCreadaId;
  String? _codigoCreado;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionar({required bool desdeCamara}) async {
    if (_enviando) return;
    try {
      final archivo = desdeCamara
          ? await widget.selectorImagen.tomarFoto()
          : await widget.selectorImagen.elegirImagen();
      if (archivo == null || !mounted) return;
      await _usarArchivo(archivo);
    } on PlatformException catch (error) {
      if (!mounted) return;
      final denegado =
          error.code.contains('denied') || error.code.contains('restricted');
      setState(() {
        _errorApi = denegado
            ? 'No se otorgó permiso para usar la cámara o la galería.'
            : 'No se pudo seleccionar la imagen.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorApi = 'No se pudo seleccionar la imagen.');
    }
  }

  Future<void> _usarArchivo(XFile archivo) async {
    final tamano = await archivo.length();
    if (!mounted) return;
    if (tamano > tamanoMaximoEvidencia) {
      setState(() {
        _archivo = archivo;
        _vistaPrevia = null;
        _errorApi = 'El archivo excede el tamaño máximo permitido de 20 MB.';
      });
      return;
    }

    try {
      final bytes = await archivo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _archivo = archivo;
        _vistaPrevia = bytes;
        _errorApi = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorApi = 'No se pudo usar la imagen seleccionada.');
    }
  }

  void _quitarArchivo() {
    setState(() {
      _archivo = null;
      _vistaPrevia = null;
      _errorApi = null;
    });
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    setState(() => _errorApi = null);
    if (!_formKey.currentState!.validate()) return;

    if (_archivo != null) {
      final tamano = await _archivo!.length();
      if (tamano > tamanoMaximoEvidencia) {
        if (!mounted) return;
        setState(() {
          _errorApi = 'El archivo excede el tamaño máximo permitido de 20 MB.';
        });
        return;
      }
    }

    setState(() => _enviando = true);
    try {
      final codigo = await _crearSiHaceFalta();
      final evidenciaFallida = await _adjuntarSiHayArchivo();
      if (!mounted) return;
      Navigator.of(context).pop(
        ResultadoNuevaSolicitud(
          codigoTicket: codigo,
          evidenciaFallida: evidenciaFallida,
        ),
      );
    } on SolicitudesException catch (error) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorApi = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorApi = 'No se pudo crear la solicitud.';
      });
    }
  }

  Future<String> _crearSiHaceFalta() async {
    final codigoExistente = _codigoCreado;
    if (_solicitudCreadaId != null && codigoExistente != null) {
      return codigoExistente;
    }

    final solicitud = await widget.solicitudesService.crear(
      titulo: _tituloController.text,
      descripcion: _descripcionController.text,
      categoria: _categoria!,
      prioridad: _prioridad!,
      solicitanteId: widget.solicitanteId,
    );
    _solicitudCreadaId = solicitud.id;
    _codigoCreado = solicitud.codigoTicket;
    return solicitud.codigoTicket;
  }

  Future<bool> _adjuntarSiHayArchivo() async {
    final archivo = _archivo;
    final solicitudId = _solicitudCreadaId;
    if (archivo == null || solicitudId == null) return false;

    try {
      await widget.solicitudesService.adjuntarEvidencia(
        solicitudId: solicitudId,
        usuarioId: widget.solicitanteId,
        archivo: archivo,
      );
      return false;
    } catch (_) {
      return true;
    }
  }

  String? _validarTitulo(String? value) {
    final titulo = value?.trim() ?? '';
    if (titulo.isEmpty) return 'El título es obligatorio.';
    if (titulo.length > 200) {
      return 'El título no puede exceder los 200 caracteres.';
    }
    return null;
  }

  String? _validarDescripcion(String? value) {
    final descripcion = value?.trim() ?? '';
    if (descripcion.isEmpty) return 'La descripción es obligatoria.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final archivo = _archivo;

    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Nueva solicitud')),
        body: AppFrame(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSection(
                          titulo: 'Información del problema',
                          child: Column(
                            children: [
                              TextFormField(
                                key: const Key('campo-titulo'),
                                controller: _tituloController,
                                enabled: !_enviando,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Título',
                                ),
                                validator: _validarTitulo,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('campo-descripcion'),
                                controller: _descripcionController,
                                enabled: !_enviando,
                                minLines: 6,
                                maxLines: 8,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción',
                                  alignLabelWithHint: true,
                                ),
                                validator: _validarDescripcion,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppSection(
                          titulo: 'Clasificación',
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                key: const Key('campo-categoria'),
                                initialValue: _categoria,
                                decoration: const InputDecoration(
                                  labelText: 'Categoría',
                                ),
                                items: [
                                  for (final opcion in _categorias)
                                    DropdownMenuItem(
                                      value: opcion.valor,
                                      child: Text(opcion.etiqueta),
                                    ),
                                ],
                                onChanged: _enviando
                                    ? null
                                    : (valor) =>
                                          setState(() => _categoria = valor),
                                validator: (valor) {
                                  if (valor == null || valor.isEmpty) {
                                    return 'Selecciona una categoría.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                key: const Key('campo-prioridad'),
                                initialValue: _prioridad,
                                decoration: const InputDecoration(
                                  labelText: 'Prioridad',
                                ),
                                items: [
                                  for (final opcion in _prioridades)
                                    DropdownMenuItem(
                                      value: opcion.valor,
                                      child: Text(opcion.etiqueta),
                                    ),
                                ],
                                onChanged: _enviando
                                    ? null
                                    : (valor) =>
                                          setState(() => _prioridad = valor),
                                validator: (valor) {
                                  if (valor == null || valor.isEmpty) {
                                    return 'Selecciona una prioridad.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppSection(
                          titulo: 'Evidencia (opcional)',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    key: const Key('boton-tomar-foto'),
                                    onPressed: _enviando
                                        ? null
                                        : () => _seleccionar(desdeCamara: true),
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                    ),
                                    label: const Text('Tomar foto'),
                                  ),
                                  OutlinedButton.icon(
                                    key: const Key('boton-elegir-imagen'),
                                    onPressed: _enviando
                                        ? null
                                        : () =>
                                              _seleccionar(desdeCamara: false),
                                    icon: const Icon(Icons.photo_outlined),
                                    label: const Text('Elegir imagen'),
                                  ),
                                ],
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                alignment: Alignment.topCenter,
                                child: archivo == null
                                    ? const SizedBox(width: double.infinity)
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: _VistaEvidencia(
                                          nombre: archivo.name,
                                          bytes: _vistaPrevia,
                                          onQuitar: _enviando
                                              ? null
                                              : _quitarArchivo,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _errorApi == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    _errorApi!,
                                    key: ValueKey(_errorApi),
                                    style: TextStyle(color: colores.error),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                color: colores.surface,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        key: const Key('boton-enviar'),
                        onPressed: _enviando ? null : _enviar,
                        child: _enviando
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colores.onPrimary,
                                ),
                              )
                            : const Text('Enviar solicitud'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _enviando
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VistaEvidencia extends StatelessWidget {
  final String nombre;
  final Uint8List? bytes;
  final VoidCallback? onQuitar;

  const _VistaEvidencia({
    required this.nombre,
    required this.bytes,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final imagen = bytes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imagen == null
                  ? Container(
                      width: 72,
                      height: 72,
                      color: colores.surfaceContainerHighest,
                      child: Icon(Icons.image_outlined, color: colores.primary),
                    )
                  : Image.memory(
                      imagen,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nombre,
                key: const Key('nombre-evidencia'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              key: const Key('boton-quitar-evidencia'),
              onPressed: onQuitar,
              tooltip: 'Quitar evidencia',
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
