import 'package:flutter/material.dart';

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
        Color(0xFFFFF4D6),
        Color(0xFF8A5A00),
      );
    case 'EnProceso':
      return const _EstiloEstado(
        'En proceso',
        Color(0xFFE3F2FD),
        Color(0xFF0D47A1),
      );
    case 'Atendida':
      return const _EstiloEstado(
        'Atendida',
        Color(0xFFE5F6EE),
        Color(0xFF0B6E4F),
      );
    case 'Cancelada':
      return const _EstiloEstado(
        'Cancelada',
        Color(0xFFEEEEEE),
        Color(0xFF616161),
      );
    case 'Rechazada':
      return const _EstiloEstado(
        'Rechazada',
        Color(0xFFFDECEA),
        Color(0xFFB3261E),
      );
    default:
      return _EstiloEstado(
        estado,
        const Color(0xFFEEEEEE),
        const Color(0xFF424242),
      );
  }
}
