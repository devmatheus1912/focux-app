import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';
import 'package:focux_app/core/widgets/fx_conversion.dart';
import 'package:focux_app/core/widgets/fx_tonal_button.dart';
import 'package:focux_app/features/auth/utils/esqueci_senha_display.dart';
import 'package:focux_app/features/auth/utils/login_display.dart';
import 'package:focux_app/features/auth/widgets/apple_sign_in_button.dart';
import 'package:focux_app/features/auth/widgets/auth_legal_consent_text.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('um slogan só', () {
    test('o do aluno é o mesmo do personal', () {
      expect(FocuxBrandCopy.onboardingHookAluno, FocuxBrandCopy.onboardingHook);
      expect(
        FocuxBrandCopy.onboardingHookAlunoHighlight,
        FocuxBrandCopy.onboardingHookHighlight,
      );
      expect(
        FocuxBrandCopy.onboardingHook.endsWith(
          FocuxBrandCopy.onboardingHookHighlight,
        ),
        isTrue,
      );
    });
  });

  group('rodapé do login por papel', () {
    test('personal cria conta; aluno ativa com convite', () {
      expect(loginRodapeTexto(isAluno: false), 'Não tem conta? ');
      expect(loginRodapeAcao(isAluno: false), 'Criar conta grátis');
      expect(loginRodapeTexto(isAluno: true), 'Recebeu um convite? ');
      expect(loginRodapeAcao(isAluno: true), 'Ativar conta');
    });
  });

  group('texto legal', () {
    testWidgets('no login é curto, sem a regra de conteúdo', (tester) async {
      await tester.pumpWidget(
        _app(const AuthLegalConsentText(primary: Colors.teal)),
      );
      final texto = tester.widget<Text>(find.byType(Text).first);
      final plano = texto.textSpan!.toPlainText();
      expect(plano, contains('Ao continuar, você aceita os Termos de uso'));
      expect(plano, isNot(contains('Conteúdo ofensivo')));
    });

    testWidgets('ao criar conta traz também a regra de conteúdo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const AuthLegalConsentText(primary: Colors.teal, completo: true)),
      );
      final texto = tester.widget<Text>(find.byType(Text).first);
      final plano = texto.textSpan!.toPlainText();
      expect(plano, contains('Ao criar, você concorda com os Termos de uso'));
      expect(plano, contains('Conteúdo ofensivo ou abusivo não é tolerado'));
    });
  });

  group('links com superfície', () {
    testWidgets('FxConversionTextLink: a ação é um botão tonal que responde', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        _app(
          FxConversionTextLink(
            text: 'Não tem conta? ',
            actionText: 'Criar conta grátis',
            onTap: () => toques++,
          ),
        ),
      );
      expect(find.byType(FxTonalButton), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      await tester.tap(find.text('Criar conta grátis'));
      expect(toques, 1);
    });

    testWidgets('sem frase, só o botão', (tester) async {
      await tester.pumpWidget(
        _app(
          FxConversionTextLink(
            text: '',
            actionText: 'Esqueci minha senha',
            onTap: () {},
          ),
        ),
      );
      expect(find.byType(FxTonalButton), findsOneWidget);
    });
  });

  testWidgets('Apple no escuro usa a variante branca da Apple', (tester) async {
    await tester.pumpWidget(
      _app(AppleSignInButton(onPressed: () {}, isLoading: false)),
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppleSignInButton),
        matching: find.byType(Material),
      ).first,
    );
    expect(material.color, const Color(0xFFFFFFFF));
  });

  group('recuperar senha do aluno', () {
    test('tem três passos e uma mensagem pronta para o personal', () {
      expect(esqueciAlunoPassos(), hasLength(3));
      expect(esqueciAlunoMensagem(), contains('Enviar link para nova senha'));
      expect(esqueciAlunoCopiarLabel(), 'Copiar mensagem para o meu personal');
    });

    test('só o personal recebe código por e-mail', () {
      expect(esqueciMostraCodigo(isAluno: false), isTrue);
      expect(esqueciMostraCodigo(isAluno: true), isFalse);
    });
  });
}
