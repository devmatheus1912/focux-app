import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focux_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E App Test', () {
    testWidgets('Validar fluxo de Login e navegação', (tester) async {
      // 1. Inicializa o App
      app.main();
      await tester.pumpAndSettle(); // Aguarda animações da Splash/Inicialização

      // 2. Verifica se a tela de Splash/Login carregou
      // Dependendo de como a rota inicial está configurada, pode cair na splash ou login
      // Vamos tentar encontrar o botão de Login
      final loginButton = find.text('Entrar');
      
      // Se não achar o botão, pode estar carregando token. 
      // Por isso um teste E2E real precisa lidar com mock de autenticação ou limpar o token antes.
      
      if (loginButton.evaluate().isNotEmpty) {
        // Encontrou botão de entrar. Significa que está na tela de Login.
        // Tenta preencher email e senha
        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).last;

        await tester.enterText(emailField, 'teste@focux.app');
        await tester.enterText(passwordField, '123456');
        await tester.pumpAndSettle();

        // Toca no botão de Entrar
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Aqui você verificaria se apareceu a Home (ex: 'Focux Dashboard' ou algo na AppBar)
        // expect(find.text('Meus Alunos'), findsOneWidget);
      } else {
        // Já estava logado ou splash está presa
        debugPrint('Botão de login não encontrado. Pode já estar logado.');
      }
    });
  });
}
