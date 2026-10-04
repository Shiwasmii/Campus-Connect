import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EstadoChip extends StatelessWidget {
  final String estado;

  const EstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final estilo = _estiloEstado(estado);
    return Chip(
      label: Text(estilo.texto),
      backgroundColor: estilo.fondo,
      labelStyle: TextStyle(
        color: estilo.textoColor,
        fontWeight: FontWeight.w600,
      ),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _EstiloEstado {
  final String texto;
  final Color fondo;
  final Color textoColor;

  const _EstiloEstado(this.texto, this.fondo, this.textoColor);
}

_EstiloEstado _estiloEstado(String estado) {
  switch (estado) {
    case 'Pendiente':
      return const _EstiloEstado(
        'Pendiente',
        AppColors.pendienteFondo,
        AppColors.pendienteTexto,
      );
    case 'EnProceso':
      return const _EstiloEstado(
        'En proceso',
        AppColors.procesoFondo,
        AppColors.procesoTexto,
      );
    case 'Atendida':
      return const _EstiloEstado(
        'Atendida',
        AppColors.atendidaFondo,
        AppColors.atendidaTexto,
      );
    case 'Cancelada':
      return const _EstiloEstado(
        'Cancelada',
        AppColors.canceladaFondo,
        AppColors.canceladaTexto,
      );
    case 'Rechazada':
      return const _EstiloEstado(
        'Rechazada',
        AppColors.rechazadaFondo,
        AppColors.rechazadaTexto,
      );
    default:
      return _EstiloEstado(
        estado,
        AppColors.neutroFondo,
        AppColors.neutroTexto,
      );
  }
}
