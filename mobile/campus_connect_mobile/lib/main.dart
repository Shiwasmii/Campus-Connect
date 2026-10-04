import 'package:flutter/material.dart';

import 'models/usuario.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'storage/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sesion = await SessionStorage().obtenerUsuario();
  runApp(CampusConnectApp(sesionInicial: sesion));
}

class CampusConnectApp extends StatelessWidget {
  final Usuario? sesionInicial;

  const CampusConnectApp({super.key, this.sesionInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: sesionInicial == null
          ? LoginScreen()
          : HomeScreen(usuario: sesionInicial!),
    );
  }
}
