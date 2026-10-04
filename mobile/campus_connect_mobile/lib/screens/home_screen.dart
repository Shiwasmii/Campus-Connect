import 'package:flutter/material.dart';

import '../models/solicitud.dart';
import '../models/usuario.dart';
import '../services/solicitudes_service.dart';
import '../storage/session_storage.dart';
import '../services/selector_imagen.dart';
import '../utils/nombre_visible.dart';
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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resultado.mensaje)),
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

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Connect')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${nombreVisible(widget.usuario.nombreCompleto)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(Icons.badge_outlined, color: colores.primary),
                    label: Text(widget.usuario.rol),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Mis solicitudes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _cargar,
                child: _contenido(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _abrirNuevaSolicitud,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva solicitud'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cerrandoSesion ? null : _cerrarSesion,
                    icon: _cerrandoSesion
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando && _solicitudes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Center(child: Text('Cargando solicitudes...')),
        ],
      );
    }

    if (_error != null && _solicitudes.isEmpty) {
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

    if (_solicitudes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no tienes solicitudes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando registres una, aparecerá en esta lista.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
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
