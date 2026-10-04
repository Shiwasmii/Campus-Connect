import 'package:flutter/material.dart';

import 'models/usuario.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'storage/session_storage.dart';
import 'theme/app_theme.dart';

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
      theme: AppTheme.light(),
      home: sesionInicial == null
          ? LoginScreen()
          : HomeScreen(usuario: sesionInicial!),
    );
  }
}
