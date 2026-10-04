import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  final String mensaje;

  const AppLoading({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 72),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),
        Center(
          child: Text(mensaje, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
