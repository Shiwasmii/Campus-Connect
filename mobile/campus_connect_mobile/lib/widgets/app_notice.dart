import 'package:flutter/material.dart';

void mostrarAviso(
  BuildContext context,
  String mensaje, {
  bool esError = false,
}) {
  final colores = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: esError ? colores.error : colores.inverseSurface,
    ),
  );
}
