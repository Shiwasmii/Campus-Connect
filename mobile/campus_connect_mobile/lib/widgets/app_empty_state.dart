import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final bool compacto;

  const AppEmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 0 : 8,
        vertical: compacto ? 8 : 24,
      ),
      child: Column(
        children: [
          Icon(icono, size: compacto ? 36 : 56, color: colores.primary),
          SizedBox(height: compacto ? 8 : 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colores.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
