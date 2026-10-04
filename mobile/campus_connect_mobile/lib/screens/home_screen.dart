import 'package:flutter/material.dart';

import '../models/solicitud.dart';
import '../models/usuario.dart';
import '../services/solicitudes_service.dart';
import '../storage/session_storage.dart';
import '../services/selector_imagen.dart';
import '../utils/nombre_visible.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_notice.dart';
import '../widgets/app_section.dart';
import '../widgets/solicitud_card.dart';
import 'login_screen.dart';
import 'nueva_solicitud_screen.dart';
import 'seguimiento_screen.dart';

class HomeScreen extends StatefulWidget {
  final Usuario usuario;
  final SessionStorage sessionStorage;
  final SolicitudesService solicitudesService;
  final SelectorImagen? selectorImagen;

  HomeScreen({
    super.key,
    required this.usuario,
    SessionStorage? sessionStorage,
    SolicitudesService? solicitudesService,
    this.selectorImagen,
  }) : sessionStorage = sessionStorage ?? SessionStorage(),
       solicitudesService = solicitudesService ?? SolicitudesService();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Solicitud> _solicitudes = [];
  bool _cargando = true;
  bool _cerrandoSesion = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final mostrarIndicador = _solicitudes.isEmpty;
    if (mostrarIndicador && !(_cargando && _error == null)) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    } else if (_error != null) {
      setState(() => _error = null);
    }

    try {
      final lista = await widget.solicitudesService.obtenerPorSolicitante(
        widget.usuario.id,
      );
      if (!mounted) return;
      setState(() {
        _solicitudes
          ..clear()
          ..addAll(lista);
        _cargando = false;
        _error = null;
      });
    } on SolicitudesException catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar las solicitudes.';
      });
    }
  }

  Future<void> _cerrarSesion() async {
    setState(() => _cerrandoSesion = true);
    await widget.sessionStorage.cerrarSesion();
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  Future<void> _abrirNuevaSolicitud() async {
    final resultado = await Navigator.of(context).push<ResultadoNuevaSolicitud>(
      MaterialPageRoute(
        builder: (_) => NuevaSolicitudScreen(
          solicitanteId: widget.usuario.id,
          solicitudesService: widget.solicitudesService,
          selectorImagen: widget.selectorImagen,
        ),
      ),
    );
    if (!mounted || resultado == null || resultado.codigoTicket.isEmpty) {
      return;
    }

    await _cargar();
    if (!mounted) return;
    mostrarAviso(
      context,
      resultado.mensaje,
      esError: resultado.evidenciaFallida,
    );
  }

  void _abrirSeguimiento(Solicitud solicitud) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeguimientoScreen(
          solicitudId: solicitud.id,
          solicitudesService: widget.solicitudesService,
        ),
      ),
    );
  }

  bool get _mostrarResumen {
    if (_cargando && _solicitudes.isEmpty) return false;
    if (_error != null && _solicitudes.isEmpty) return false;
    return true;
  }

  int get _pendientes =>
      _solicitudes.where((solicitud) => solicitud.estado == 'Pendiente').length;

  int get _enProceso =>
      _solicitudes.where((solicitud) => solicitud.estado == 'EnProceso').length;

  String get _vista {
    if (_cargando && _solicitudes.isEmpty) return 'cargando';
    if (_error != null && _solicitudes.isEmpty) return 'error';
    if (_solicitudes.isEmpty) return 'vacio';
    return 'lista';
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Connect')),
      body: AppFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Encabezado(
                    nombre: nombreVisible(widget.usuario.nombreCompleto),
                    rol: widget.usuario.rol,
                  ),
                  if (_mostrarResumen) ...[
                    const SizedBox(height: 16),
                    _ResumenSolicitudes(
                      total: _solicitudes.length,
                      pendientes: _pendientes,
                      enProceso: _enProceso,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Mis solicitudes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _cargar,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_vista),
                    child: _contenido(),
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
                    FilledButton.icon(
                      onPressed: _abrirNuevaSolicitud,
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva solicitud'),
                    ),
                    TextButton.icon(
                      onPressed: _cerrandoSesion ? null : _cerrarSesion,
                      icon: _cerrandoSesion
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colores.primary,
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando && _solicitudes.isEmpty) {
      return const AppLoading(mensaje: 'Cargando solicitudes...');
    }

    if (_error != null && _solicitudes.isEmpty) {
      return AppErrorState(mensaje: _error!, onRetry: _cargar);
    }

    if (_solicitudes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: const [
          AppEmptyState(
            icono: Icons.inbox_outlined,
            titulo: 'Todavía no tienes solicitudes.',
            mensaje: 'Cuando registres una, aparecerá en esta lista.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      itemCount: _solicitudes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final solicitud = _solicitudes[index];
        return SolicitudCard(
          solicitud: solicitud,
          onTap: () => _abrirSeguimiento(solicitud),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String nombre;
  final String rol;

  const _Encabezado({required this.nombre, required this.rol});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colores.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colores.primary,
            foregroundColor: colores.onPrimary,
            child: Text(
              nombre.isEmpty ? '?' : nombre[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $nombre',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colores.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rol,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colores.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenSolicitudes extends StatelessWidget {
  final int total;
  final int pendientes;
  final int enProceso;

  const _ResumenSolicitudes({
    required this.total,
    required this.pendientes,
    required this.enProceso,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DatoResumen(valor: total, etiqueta: 'Total'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DatoResumen(valor: pendientes, etiqueta: 'Pendientes'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DatoResumen(valor: enProceso, etiqueta: 'En proceso'),
        ),
      ],
    );
  }
}

class _DatoResumen extends StatelessWidget {
  final int valor;
  final String etiqueta;

  const _DatoResumen({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Text(
              '$valor',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
