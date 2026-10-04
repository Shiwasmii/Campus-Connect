import 'package:flutter/material.dart';

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
        Color(0xFFE8F5E9),
        Color(0xFF2E7D32),
      );
    case 'Media':
      return const _EstiloPrioridad(
        'Media',
        Color(0xFFE3F2FD),
        Color(0xFF1565C0),
      );
    case 'Alta':
      return const _EstiloPrioridad(
        'Alta',
        Color(0xFFFFF3E0),
        Color(0xFFE65100),
      );
    case 'Urgente':
      return const _EstiloPrioridad(
        'Urgente',
        Color(0xFFFDECEA),
        Color(0xFFB3261E),
      );
    default:
      return _EstiloPrioridad(
        prioridad,
        const Color(0xFFEEEEEE),
        const Color(0xFF424242),
      );
  }
}
