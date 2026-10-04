import 'package:flutter/material.dart';

import '../models/solicitud.dart';
import '../utils/nombre_visible.dart';
import 'estado_chip.dart';
import 'prioridad_chip.dart';

class SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback onTap;

  const SolicitudCard({
    super.key,
    required this.solicitud,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textoSecundario = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: colores.onSurfaceVariant);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(solicitud.codigoTicket, style: textoSecundario),
              const SizedBox(height: 4),
              Text(
                solicitud.titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(solicitud.categoriaVisible, style: textoSecundario),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  EstadoChip(estado: solicitud.estado),
                  PrioridadChip(prioridad: solicitud.prioridad),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: colores.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      solicitud.fechaCreacionVisible,
                      style: textoSecundario,
                    ),
                  ),
                ],
              ),
              if (solicitud.tieneResponsable) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: colores.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Responsable: ${nombreVisible(solicitud.asignadoANombre!)}',
                        style: textoSecundario,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
