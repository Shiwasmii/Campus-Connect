import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../storage/session_storage.dart';
import '../widgets/app_section.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final SessionStorage sessionStorage;

  LoginScreen({
    super.key,
    AuthService? authService,
    SessionStorage? sessionStorage,
  }) : authService = authService ?? AuthService(),
       sessionStorage = sessionStorage ?? SessionStorage();

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _cargando = false;
  bool _ocultarPassword = true;
  String? _errorApi;

  static final _correoRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    setState(() => _errorApi = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _cargando = true);
    final resultado = await widget.authService.login(
      _correoController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (!resultado.exitoso ||
        resultado.usuario == null ||
        resultado.token == null) {
      setState(() {
        _cargando = false;
        _errorApi = resultado.mensaje;
      });
      return;
    }

    await widget.sessionStorage.guardar(resultado.usuario!, resultado.token!);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          usuario: resultado.usuario!,
          sessionStorage: widget.sessionStorage,
        ),
      ),
    );
  }

  String? _validarCorreo(String? value) {
    final correo = value?.trim() ?? '';
    if (correo.isEmpty) {
      return 'Ingresa tu correo.';
    }
    if (!_correoRegExp.hasMatch(correo)) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      body: AppFrame(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 64).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: colores.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: 42,
                          color: colores.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Campus Connect',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para ver tus solicitudes',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _correoController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                enabled: !_cargando,
                                decoration: const InputDecoration(
                                  labelText: 'Correo',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: _validarCorreo,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _ocultarPassword,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                enabled: !_cargando,
                                onFieldSubmitted: (_) => _iniciarSesion(),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _ocultarPassword
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    onPressed: _cargando
                                        ? null
                                        : () {
                                            setState(() {
                                              _ocultarPassword =
                                                  !_ocultarPassword;
                                            });
                                          },
                                    icon: Icon(
                                      _ocultarPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: _validarPassword,
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _errorApi == null
                                    ? const SizedBox(width: double.infinity)
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Text(
                                          _errorApi!,
                                          key: ValueKey(_errorApi),
                                          style: TextStyle(
                                            color: colores.error,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _cargando ? null : _iniciarSesion,
                                child: _cargando
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colores.onPrimary,
                                        ),
                                      )
                                    : const Text('Iniciar sesión'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
