class Usuario {
  final int id;
  final String nombreCompleto;
  final String correo;
  final String rol;

  const Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombreCompleto: json['nombreCompleto'] as String,
      correo: json['correo'] as String,
      rol: json['rol'] as String,
    );
  }
}
