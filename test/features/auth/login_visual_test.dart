import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/features/auth/data/auth_repository.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/auth/screens/login_screen.dart';
import 'package:focux_app/features/auth/services/biometria_login.dart';
import 'package:focux_app/features/auth/widgets/auth_social_button.dart';
import 'package:focux_app/features/auth/widgets/auth_social_stack.dart';
import 'package:focux_app/features/auth/widgets/auth_text_link.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthOffline implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(StateError('offline'));
}

class _SistemaFalso implements BiometriaSistema {
  _SistemaFalso({this.tipo = BiometriaTipo.faceId, this.aceita = true});
  final BiometriaTipo? tipo;
  bool aceita;
  int pedidos = 0;

  @override
  Future<BiometriaTipo?> tipoDisponivel() async => tipo;

  @override
  Future<bool> autenticar(String motivo) async {
    pedidos++;
    return aceita;
  }
}

class _CofreFalso implements BiometriaCofre {
  CredencialBiometria? guardada;

  @override
  Future<CredencialBiometria?> ler() async => guardada;

  @override
  Future<void> gravar(CredencialBiometria credencial) async =>
      guardada = credencial;

  @override
  Future<void> apagar() async => guardada = null;
}

Future<void> _abrir(
  WidgetTester tester,
  String rota, {
  Size tela = const Size(390, 844),
  BiometriaLogin? biometria,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.binding.setSurfaceSize(tela);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: rota,
    routes: [GoRoute(path: '/login', builder: (_, __) => const LoginScreen())],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthOffline()),
        if (biometria != null)
          biometriaLoginProvider.overrideWithValue(biometria),
      ],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final escuro = la > lb ? lb : la;
  return (claro + 0.05) / (escuro + 0.05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('layout', () {
    testWidgets('sem card, sem título "Entrar" e sem o ícone de ajuda', (
      tester,
    ) async {
      await _abrir(tester, '/login');
      // o único "Entrar" é o botão
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.byTooltip('Entrar no Focux'), findsNothing);
      expect(find.text('Precisa de ajuda?'), findsOneWidget);
    });

    testWidgets('sem link só existe o login do personal', (tester) async {
      await _abrir(tester, '/login');
      expect(find.text('Personal'), findsNothing);
      expect(find.text('Aluno'), findsNothing);
      expect(find.text('Código do personal'), findsNothing);
      expect(find.text('Criar conta grátis'), findsOneWidget);
      expect(find.text('Digitar o código do personal'), findsOneWidget);
    });

    testWidgets('o formulário começa antes de 45% da altura (390×844)', (
      tester,
    ) async {
      await _abrir(tester, '/login');
      final topo = tester.getTopLeft(find.text('E-mail')).dy;
      expect(topo, lessThan(844 * 0.45));
    });

    testWidgets('com o teclado aberto, Entrar fica acima dele', (tester) async {
      await _abrir(tester, '/login', tela: const Size(390, 844));
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump(const Duration(milliseconds: 300));
      final entrar = find.text('Entrar');
      await tester.ensureVisible(entrar);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(entrar).bottom, lessThanOrEqualTo(844 - 300));
    });

    for (final (nome, tela, escala) in [
      ('390×844', const Size(390, 844), 1.0),
      ('360×690 com letra 1,3x', const Size(360, 690), 1.3),
    ]) {
      testWidgets('em $nome o botão Entrar aparece sem rolar', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _abrir(tester, '/login', tela: tela);
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.text('Entrar')).bottom,
          lessThanOrEqualTo(tela.height),
        );
      });
    }
  });

  group('papel', () {
    testWidgets('com link de aluno mostra o contexto e Ativar conta', (
      tester,
    ) async {
      await _abrir(tester, '/login?role=aluno&p=ana');
      expect(find.byKey(const ValueKey('login-contexto-aluno')), findsOneWidget);
      expect(find.textContaining('ana'), findsWidgets);
      expect(find.text('Trocar'), findsOneWidget);
      expect(find.text('Ativar conta'), findsOneWidget);
      expect(find.text('Criar conta grátis'), findsNothing);
      expect(find.text('Código do personal'), findsNothing);
    });

    testWidgets('Trocar mostra o campo e Sou personal volta ao personal', (
      tester,
    ) async {
      await _abrir(tester, '/login?role=aluno&p=ana');
      await tester.tap(find.text('Trocar'));
      await tester.pump();
      expect(find.text('Código do personal'), findsOneWidget);
      await tester.ensureVisible(find.text('Sou personal'));
      await tester.tap(find.text('Sou personal'));
      await tester.pump();
      expect(find.text('Criar conta grátis'), findsOneWidget);
      expect(find.text('Código do personal'), findsNothing);
    });

    testWidgets('"Digitar o código do personal" abre o campo vazio', (
      tester,
    ) async {
      await _abrir(tester, '/login');
      await tester.ensureVisible(find.text('Digitar o código do personal'));
      await tester.tap(find.text('Digitar o código do personal'));
      await tester.pump();
      expect(find.text('Código do personal'), findsOneWidget);
      expect(find.text('Ativar conta'), findsOneWidget);
    });
  });

  group('botões sociais', () {
    testWidgets('mesmo verbo, uma linha em 320 dp e mesmo estilo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: AuthSocialStack(
                mostrarApple: true,
                mostrarGoogle: true,
                onApple: () {},
                onGoogle: () {},
                carregandoApple: false,
                carregandoGoogle: false,
              ),
            ),
          ),
        ),
      );
      final apple = find.text('Continuar com Apple');
      final google = find.text('Continuar com Google');
      expect(apple, findsOneWidget);
      expect(google, findsOneWidget);
      expect(tester.getSize(apple).height, lessThan(24));
      expect(tester.getSize(google).height, lessThan(24));
      // empilhados, mesma largura e mesma altura
      final a = tester.getRect(find.byType(AuthSocialButton).first);
      final g = tester.getRect(find.byType(AuthSocialButton).at(1));
      expect(g.top, greaterThan(a.bottom));
      expect(a.width, g.width);
      expect(a.height, g.height);
    });
  });

  group('contraste', () {
    const fundoClaro = Color(0xFF0D2830); // ponto mais claro do fundo
    const fundoEscuro = Color(0xFF0B0E14);

    Color sobre(Color fundo, Color frente) => Color.alphaBlend(frente, fundo);

    testWidgets('link de texto lê ≥ 4,5:1 sobre o fundo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brand),
          ),
          home: Scaffold(
            body: AuthTextLink(label: 'Criar conta grátis', onTap: () {}),
          ),
        ),
      );
      final cor = tester.widget<Text>(find.text('Criar conta grátis')).style!.color!;
      expect(_contraste(cor, fundoClaro), greaterThanOrEqualTo(4.5));
      expect(_contraste(cor, fundoEscuro), greaterThanOrEqualTo(4.5));
    });

    test('texto de apoio (branco 82%) lê ≥ 4,5:1', () {
      final apoio = Colors.white.withValues(alpha: 0.82);
      expect(
        _contraste(sobre(fundoClaro, apoio), fundoClaro),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('rótulo branco do Entrar lê ≥ 4,5:1 em toda a faixa do degradê', () {
      final degrade = TokensStrip.primaryButtonGradient(EagleTokens.brand);
      for (final cor in degrade.colors) {
        expect(
          _contraste(Colors.white, cor.withValues(alpha: 1)),
          greaterThanOrEqualTo(4.5),
          reason: 'cor $cor',
        );
      }
    });

    test('rótulo dos botões sociais lê ≥ 4,5:1', () {
      final botao = sobre(fundoClaro, Colors.white.withValues(alpha: 0.05));
      expect(_contraste(Colors.white, botao), greaterThanOrEqualTo(4.5));
    });
  });

  group('biometria', () {
    testWidgets('botão só aparece com a biometria ativa e disponível', (
      tester,
    ) async {
      await _abrir(tester, '/login');
      expect(find.byKey(const ValueKey('login-biometria')), findsNothing);
    });

    testWidgets('ativa: mostra "Entrar com Face ID"', (tester) async {
      SharedPreferences.setMockInitialValues({'biometria_login_ativa': true});
      await _abrir(
        tester,
        '/login',
        biometria: BiometriaLogin(
          sistema: _SistemaFalso(),
          cofre: _CofreFalso(),
        ),
      );
      expect(find.text('Entrar com Face ID'), findsOneWidget);
    });

    testWidgets('sem biometria no aparelho o botão some', (tester) async {
      SharedPreferences.setMockInitialValues({'biometria_login_ativa': true});
      await _abrir(
        tester,
        '/login',
        biometria: BiometriaLogin(
          sistema: _SistemaFalso(tipo: null),
          cofre: _CofreFalso(),
        ),
      );
      expect(find.byKey(const ValueKey('login-biometria')), findsNothing);
    });
  });

  group('BiometriaLogin', () {
    const cred = CredencialBiometria(
      email: 'a@b.com',
      senha: 'segredo123',
      aluno: false,
    );

    test('só guarda a credencial depois de confirmar a biometria', () async {
      SharedPreferences.setMockInitialValues({});
      final cofre = _CofreFalso();
      final sistema = _SistemaFalso(aceita: false);
      final bio = BiometriaLogin(sistema: sistema, cofre: cofre);
      expect(await bio.ativar(cred, 'x'), isFalse);
      expect(cofre.guardada, isNull);
      expect(await bio.ativa(), isFalse);

      sistema.aceita = true;
      expect(await bio.ativar(cred, 'x'), isTrue);
      expect(cofre.guardada?.email, 'a@b.com');
      expect(await bio.ativa(), isTrue);
    });

    test('entrar pede a biometria e devolve a credencial', () async {
      SharedPreferences.setMockInitialValues({});
      final cofre = _CofreFalso();
      final sistema = _SistemaFalso();
      final bio = BiometriaLogin(sistema: sistema, cofre: cofre);
      await bio.ativar(cred, 'x');
      sistema.pedidos = 0;
      final lida = await bio.entrar('x');
      expect(sistema.pedidos, 1);
      expect(lida?.senha, 'segredo123');

      sistema.aceita = false;
      expect(await bio.entrar('x'), isNull, reason: 'cancelou: nada sai');
    });

    test('desativar apaga a credencial', () async {
      SharedPreferences.setMockInitialValues({});
      final cofre = _CofreFalso();
      final bio = BiometriaLogin(sistema: _SistemaFalso(), cofre: cofre);
      await bio.ativar(cred, 'x');
      await bio.desativar();
      expect(cofre.guardada, isNull);
      expect(await bio.ativa(), isFalse);
      expect(await bio.entrar('x'), isNull);
    });

    test('"Agora não" silencia a oferta por 30 dias', () async {
      SharedPreferences.setMockInitialValues({});
      var agora = DateTime(2026, 10, 29);
      final bio = BiometriaLogin(
        sistema: _SistemaFalso(),
        cofre: _CofreFalso(),
        agora: () => agora,
      );
      expect(await bio.tipoParaOferecer(), BiometriaTipo.faceId);
      await bio.adiarOferta();
      expect(await bio.tipoParaOferecer(), isNull);
      agora = agora.add(const Duration(days: 31));
      expect(await bio.tipoParaOferecer(), BiometriaTipo.faceId);
    });

    test('atualiza a credencial só quando já está ativa', () async {
      SharedPreferences.setMockInitialValues({});
      final cofre = _CofreFalso();
      final bio = BiometriaLogin(sistema: _SistemaFalso(), cofre: cofre);
      await bio.atualizarSeAtiva(cred);
      expect(cofre.guardada, isNull);
      await bio.ativar(cred, 'x');
      await bio.atualizarSeAtiva(
        const CredencialBiometria(
          email: 'a@b.com',
          senha: 'nova',
          aluno: false,
        ),
      );
      expect(cofre.guardada?.senha, 'nova');
    });
  });
}
