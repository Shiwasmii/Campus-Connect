import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';

class SessionStorage {
  static const _claveId = 'usuario_id';
  static const _claveNombre = 'usuario_nombre';
  static const _claveCorreo = 'usuario_correo';
  static const _claveRol = 'usuario_rol';
  static const _claveToken = 'token_simulado';

  Future<void> guardar(Usuario usuario, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveId, usuario.id);
    await prefs.setString(_claveNombre, usuario.nombreCompleto);
    await prefs.setString(_claveCorreo, usuario.correo);
    await prefs.setString(_claveRol, usuario.rol);
    await prefs.setString(_claveToken, token);
  }

  Future<Usuario?> obtenerUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_claveId);
    final nombre = prefs.getString(_claveNombre);
    final correo = prefs.getString(_claveCorreo);
    final rol = prefs.getString(_claveRol);
    final token = prefs.getString(_claveToken);

    if (id == null ||
        nombre == null ||
        nombre.isEmpty ||
        correo == null ||
        correo.isEmpty ||
        rol == null ||
        rol.isEmpty ||
        token == null ||
        token.isEmpty) {
      return null;
    }

    return Usuario(id: id, nombreCompleto: nombre, correo: correo, rol: rol);
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveId);
    await prefs.remove(_claveNombre);
    await prefs.remove(_claveCorreo);
    await prefs.remove(_claveRol);
    await prefs.remove(_claveToken);
  }
}
