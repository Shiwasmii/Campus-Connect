import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PrioridadChip extends StatelessWidget {
  final String prioridad;

  const PrioridadChip({super.key, required this.prioridad});

  @override
  Widget build(BuildContext context) {
    final estilo = _estiloPrioridad(prioridad);
    return Chip(
      avatar: Icon(Icons.flag_outlined, size: 18, color: estilo.textoColor),
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

class _EstiloPrioridad {
  final String texto;
  final Color fondo;
  final Color textoColor;

  const _EstiloPrioridad(this.texto, this.fondo, this.textoColor);
}

_EstiloPrioridad _estiloPrioridad(String prioridad) {
  switch (prioridad) {
    case 'Baja':
      return const _EstiloPrioridad(
        'Baja',
        AppColors.prioridadBajaFondo,
        AppColors.prioridadBajaTexto,
      );
    case 'Media':
      return const _EstiloPrioridad(
        'Media',
        AppColors.prioridadMediaFondo,
        AppColors.prioridadMediaTexto,
      );
    case 'Alta':
      return const _EstiloPrioridad(
        'Alta',
        AppColors.prioridadAltaFondo,
        AppColors.prioridadAltaTexto,
      );
    case 'Urgente':
      return const _EstiloPrioridad(
        'Urgente',
        AppColors.prioridadUrgenteFondo,
        AppColors.prioridadUrgenteTexto,
      );
    default:
      return _EstiloPrioridad(
        prioridad,
        AppColors.neutroFondo,
        AppColors.neutroTexto,
      );
  }
}
