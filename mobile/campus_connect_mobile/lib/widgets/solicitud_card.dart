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

    return Card(
      elevation: 0,
      color: colores.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colores.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                solicitud.codigoTicket,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colores.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                solicitud.titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                solicitud.categoriaVisible,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colores.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PrioridadChip(prioridad: solicitud.prioridad),
                  EstadoChip(estado: solicitud.estado),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: colores.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    solicitud.fechaCreacionVisible,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (solicitud.tieneResponsable) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: colores.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Responsable: ${nombreVisible(solicitud.asignadoANombre!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
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
