import 'package:campus_connect_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sin sesión muestra la pantalla de login', (tester) async {
    await tester.pumpWidget(const CampusConnectApp(sesionInicial: null));

    expect(find.text('Campus Connect'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
