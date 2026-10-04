import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/usuario.dart';

class ResultadoLogin {
  final bool exitoso;
  final String mensaje;
  final Usuario? usuario;
  final String? token;

  const ResultadoLogin._({
    required this.exitoso,
    required this.mensaje,
    this.usuario,
    this.token,
  });

  factory ResultadoLogin.ok(Usuario usuario, String token, String mensaje) {
    return ResultadoLogin._(
      exitoso: true,
      mensaje: mensaje,
      usuario: usuario,
      token: token,
    );
  }

  factory ResultadoLogin.fallo(String mensaje) {
    return ResultadoLogin._(exitoso: false, mensaje: mensaje);
  }
}

class AuthService {
  Future<ResultadoLogin> login(String correo, String password) async {
    try {
      final response = await http.post(
        ApiConfig.loginUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo.trim(), 'password': password}),
      );

      final data = _leerJson(response.body);
      if (data == null) {
        return ResultadoLogin.fallo('Respuesta inesperada del servidor.');
      }

      final mensaje =
          data['mensaje'] as String? ?? 'No se pudo iniciar sesión.';
      final exitoso = data['exitoso'] == true;
      if (!exitoso) {
        return ResultadoLogin.fallo(mensaje);
      }

      final usuarioJson = data['usuario'];
      final token = data['tokenSimulado'] as String?;
      if (usuarioJson is! Map || token == null || token.isEmpty) {
        return ResultadoLogin.fallo(
          'La respuesta de la API no incluye la sesión.',
        );
      }

      final usuario = Usuario.fromJson(Map<String, dynamic>.from(usuarioJson));
      return ResultadoLogin.ok(usuario, token, mensaje);
    } on SocketException {
      return ResultadoLogin.fallo(
        'No se pudo conectar con el servidor. Verifica que la API esté en ejecución.',
      );
    } catch (_) {
      return ResultadoLogin.fallo('Ocurrió un error al iniciar sesión.');
    }
  }

  Map<String, dynamic>? _leerJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
