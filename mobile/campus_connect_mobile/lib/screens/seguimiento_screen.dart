import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/comentario.dart';
import '../models/evidencia.dart';
import '../models/seguimiento_solicitud.dart';
import '../models/solicitud.dart';
import '../services/solicitudes_service.dart';
import '../storage/session_storage.dart';
import '../utils/nombre_visible.dart';
import '../widgets/estado_chip.dart';
import '../widgets/prioridad_chip.dart';

class SeguimientoScreen extends StatefulWidget {
  final int solicitudId;
  final SolicitudesService solicitudesService;
  final SessionStorage sessionStorage;

  SeguimientoScreen({
    super.key,
    required this.solicitudId,
    SolicitudesService? solicitudesService,
    SessionStorage? sessionStorage,
  }) : solicitudesService = solicitudesService ?? SolicitudesService(),
       sessionStorage = sessionStorage ?? SessionStorage();

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  final _comentarioController = TextEditingController();
  SeguimientoSolicitud? _seguimiento;
  bool _cargando = true;
  bool _enviandoComentario = false;
  String? _error;
  String? _errorComentario;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final mostrarIndicador = _seguimiento == null;
    if (mostrarIndicador && !(_cargando && _error == null)) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final datos = await widget.solicitudesService.obtenerSeguimiento(
        widget.solicitudId,
      );
      if (!mounted) return;
      setState(() {
        _seguimiento = datos;
        _cargando = false;
        _error = null;
      });
    } on SolicitudesException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404) {
        setState(() {
          _seguimiento = null;
          _cargando = false;
          _error = 'La solicitud ya no existe.';
        });
        return;
      }
      if (_seguimiento != null) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
        return;
      }
      setState(() {
        _cargando = false;
        _error = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        if (_seguimiento == null) {
          _error = 'No se pudo cargar el seguimiento.';
        }
      });
    }
  }

  Future<void> _enviarComentario() async {
    if (_enviandoComentario) return;

    final mensaje = _comentarioController.text.trim();
    if (mensaje.isEmpty) {
      setState(() => _errorComentario = 'Escribe un comentario.');
      return;
    }

    setState(() {
      _enviandoComentario = true;
      _errorComentario = null;
    });

    try {
      final usuario = await widget.sessionStorage.obtenerUsuario();
      if (!mounted) return;
      if (usuario == null) {
        setState(() {
          _enviandoComentario = false;
          _errorComentario = 'No hay una sesión activa. Vuelve a iniciar sesión.';
        });
        return;
      }

      await widget.solicitudesService.agregarComentario(
        solicitudId: widget.solicitudId,
        usuarioId: usuario.id,
        mensaje: mensaje,
      );
      if (!mounted) return;
      _comentarioController.clear();
      setState(() => _errorComentario = null);
      await _cargar();
      if (!mounted) return;
      setState(() => _enviandoComentario = false);
    } on SolicitudesException catch (error) {
      if (!mounted) return;
      setState(() {
        _enviandoComentario = false;
        _errorComentario = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviandoComentario = false;
        _errorComentario = 'No se pudo enviar el comentario.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: _contenido(),
        ),
      ),
    );
  }

  Widget _contenido() {
    final seguimiento = _seguimiento;
    if (_cargando && seguimiento == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Center(child: Text('Cargando seguimiento...')),
        ],
      );
    }

    if (_error != null && seguimiento == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _cargar,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    if (seguimiento == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        _DetalleSolicitud(seguimiento: seguimiento),
        const SizedBox(height: 28),
        Text('Actividad', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (seguimiento.comentariosPublicos.isEmpty)
          const Text('Aún no hay actualizaciones')
        else
          for (final comentario in seguimiento.comentariosPublicos) ...[
            _ComentarioCard(comentario: comentario),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 8),
        Text(
          'Agregar comentario',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('campo-comentario'),
          controller: _comentarioController,
          enabled: !_enviandoComentario,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'Escribe una actualización...',
            alignLabelWithHint: true,
          ),
        ),
        if (_errorComentario != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorComentario!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('boton-enviar-comentario'),
          onPressed: _enviandoComentario ? null : _enviarComentario,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: _enviandoComentario
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar comentario'),
        ),
        const SizedBox(height: 28),
        Text('Evidencias', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (seguimiento.evidencias.isEmpty)
          const Text('Sin evidencias adjuntas')
        else
          for (final evidencia in seguimiento.evidencias) ...[
            _EvidenciaCard(evidencia: evidencia),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _DetalleSolicitud extends StatelessWidget {
  final SeguimientoSolicitud seguimiento;

  const _DetalleSolicitud({required this.seguimiento});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final recurso = seguimiento.recurso;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          seguimiento.codigoTicket,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colores.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          seguimiento.titulo,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            EstadoChip(estado: seguimiento.estado),
            PrioridadChip(prioridad: seguimiento.prioridad),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          seguimiento.categoriaVisible,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colores.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(seguimiento.descripcion),
        const SizedBox(height: 16),
        _Dato(
          icono: Icons.calendar_today_outlined,
          texto: 'Creada: ${formatearFecha(seguimiento.fechaCreacion)}',
        ),
        if (seguimiento.fechaActualizacion != null) ...[
          const SizedBox(height: 8),
          _Dato(
            icono: Icons.update,
            texto:
                'Actualizada: ${formatearFecha(seguimiento.fechaActualizacion!)}',
          ),
        ],
        const SizedBox(height: 8),
        _Dato(
          icono: Icons.person_outline,
          texto:
              'Responsable: ${nombreVisible(seguimiento.responsableVisible)}',
        ),
        if (recurso != null && recurso.visible.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _Dato(
            icono: Icons.inventory_2_outlined,
            texto: 'Recurso: ${recurso.visible}',
          ),
        ],
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(texto)),
      ],
    );
  }
}

class _ComentarioCard extends StatelessWidget {
  final Comentario comentario;

  const _ComentarioCard({required this.comentario});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colores.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colores.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombreVisible(comentario.usuarioNombre),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (comentario.usuarioRol.trim().isNotEmpty)
              Text(
                comentario.usuarioRol,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colores.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            Text(comentario.mensaje),
            const SizedBox(height: 8),
            Text(
              formatearFecha(comentario.fechaCreacion),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colores.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenciaCard extends StatelessWidget {
  final Evidencia evidencia;

  const _EvidenciaCard({required this.evidencia});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final url = ApiConfig.resolverUrl(evidencia.urlDescarga);

    return Card(
      elevation: 0,
      color: colores.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colores.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: evidencia.esImagen && url.isNotEmpty
                  ? Image.network(
                      url,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _icono(colores),
                    )
                  : _icono(colores),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evidencia.nombreArchivoOriginal,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subida por ${nombreVisible(evidencia.subidoPorNombre)}',
                  ),
                  Text(formatearFecha(evidencia.fechaSubida)),
                  Text(evidencia.tamanoVisible),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icono(ColorScheme colores) {
    return Container(
      width: 72,
      height: 72,
      color: colores.surfaceContainerHighest,
      child: Icon(Icons.insert_drive_file_outlined, color: colores.primary),
    );
  }
}
