import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Limita el ancho en pantallas grandes y conserva el alto de la pantalla.
class AppFrame extends StatelessWidget {
  final Widget child;

  const AppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.anchoMaximo),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppSection extends StatelessWidget {
  final String titulo;
  final IconData? icono;
  final Widget child;

  const AppSection({
    super.key,
    required this.titulo,
    required this.child,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icono != null) ...[
              Icon(icono, size: 20, color: colores.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
