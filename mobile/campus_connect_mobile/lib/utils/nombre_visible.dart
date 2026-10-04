/// Quita el rol que los usuarios semilla traen al final del nombre.
/// No modifica el valor guardado ni el que llega de la API.
String nombreVisible(String nombre) {
  final limpio = nombre.trim();
  const sufijos = ['(Estudiante)', '(Administradora)', '(Soporte TI)'];

  for (final sufijo in sufijos) {
    if (limpio.endsWith(sufijo)) {
      return limpio.substring(0, limpio.length - sufijo.length).trim();
    }
  }

  return limpio;
}
