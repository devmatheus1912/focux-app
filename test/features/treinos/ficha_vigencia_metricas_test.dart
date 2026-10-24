import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/ficha_modelo_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_modelo.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/aluno_rotina_screen.dart';
import 'package:focux_app/features/treinos/utils/ficha_vigencia.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Treinos extends TreinoRepository {
  _Treinos(this.fila, {this.falhar = false}) : super(ApiClient());

  final RotinaFila fila;
  final bool falhar;
  final renovacoes = <int>[];

  void _talvezFalhar() {
    if (falhar) throw Exception('falhou');
  }

  @override
  Future<RotinaFila> buscarRotina(int alunoId) async => fila;

  @override
  Future<RotinaFila> gravarSemana(int alunoId, List<DiaDaSemana> dias) async {
    _talvezFalhar();
    return fila;
  }

  @override
  Future<RotinaFila> definirVigenciaSemanas(int alunoId, int semanas) async {
    _talvezFalhar();
    return fila;
  }

  @override
  Future<RotinaFila> renovarVigencia(int alunoId, int semanas) async {
    _talvezFalhar();
    renovacoes.add(semanas);
    return fila;
  }

  @override
  Future<RotinaFila> copiarSemana(int alunoId, int destinoId, {bool manterCargas = true}) async {
    _talvezFalhar();
    return fila;
  }
}

class _Modelos extends FichaModeloRepository {
  _Modelos() : super(ApiClient());

  @override
  Future<List<FichaModelo>> listar() async => const [FichaModelo(id: 31, nome: 'Hipertrofia 4 dias')];

  @override
  Future<RotinaFila> aplicar(int id, int alunoId, {bool manterCargas = true}) async => RotinaFila.vazia;
}

RotinaFila _ficha({int fimEmDias = 3}) => RotinaFila(
  itens: const [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1, exerciciosCount: 5),
  ],
  vigencia: VigenciaFicha(fim: DateTime.now().add(Duration(days: fimEmDias))),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Abre a ficha e devolve o repositório e as linhas de analytics capturadas.
class _Cena {
  _Cena(this.treinos, this.logs, this.restaurar);

  final _Treinos treinos;
  final List<String> logs;
  final void Function() restaurar;
}

Future<_Cena> _abrir(
  WidgetTester tester,
  RotinaFila fila, {
  bool abrirVigencia = false,
  String origem = 'ficha',
  bool falhar = false,
}) async {
  final logs = <String>[];
  final original = debugPrint;
  debugPrint = (String? mensagem, {int? wrapWidth}) {
    if (mensagem != null && mensagem.contains('[Analytics]') && mensagem.contains('ficha_')) {
      logs.add(mensagem);
    }
  };
  await tester.binding.setSurfaceSize(const Size(430, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final treinos = _Treinos(fila, falhar: falhar);
  final router = GoRouter(
    initialLocation: '/alunos/3/rotina',
    routes: [
      GoRoute(
        path: '/alunos/:id/rotina',
        builder: (context, state) => AlunoRotinaScreen(
          alunoId: 3,
          alunoNome: 'Ana',
          abrirVigencia: abrirVigencia,
          origem: origem,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        treinoRepositoryProvider.overrideWithValue(treinos),
        fichaModeloRepositoryProvider.overrideWithValue(_Modelos()),
      ],
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
  return _Cena(treinos, logs, () => debugPrint = original);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('aviso e Hoje abrem a ficha com o menu de renovar', () {
    testWidgets('abre o menu sozinho, renova por 8 semanas e registra a origem', (tester) async {
      final cena = await _abrir(tester, _ficha(), abrirVigencia: true, origem: 'aviso');

      expect(find.text('Vigência da ficha'), findsOneWidget);
      await tester.tap(find.text('Renovar por 8 semanas'));
      await _settle(tester);
      cena.restaurar();

      expect(cena.treinos.renovacoes, [8]);
      expect(cena.logs, hasLength(1));
      expect(cena.logs.single, contains('ficha_renovada'));
      expect(cena.logs.single, contains('origem: aviso'));
      expect(cena.logs.single, contains('semanas: 8'));
    });

    testWidgets('vindo do Hoje, a origem é hoje', (tester) async {
      final cena = await _abrir(tester, _ficha(), abrirVigencia: true, origem: 'hoje');
      await tester.tap(find.text('Renovar por 4 semanas'));
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs.single, contains('origem: hoje'));
      expect(cena.logs.single, contains('semanas: 4'));
    });

    testWidgets('sem o pedido, o menu não abre sozinho', (tester) async {
      final cena = await _abrir(tester, _ficha());
      cena.restaurar();

      expect(find.text('Vigência da ficha'), findsNothing);
      expect(find.text('Vigência'), findsOneWidget);
    });

    testWidgets('ficha vazia não abre o menu de renovar', (tester) async {
      final cena = await _abrir(tester, RotinaFila.vazia, abrirVigencia: true);
      cena.restaurar();

      expect(find.text('Vigência da ficha'), findsNothing);
    });

    testWidgets('fechar o menu sem escolher não registra nada e não reabre', (tester) async {
      final cena = await _abrir(tester, _ficha(), abrirVigencia: true, origem: 'aviso');
      Navigator.of(tester.element(find.text('Vigência da ficha'))).pop();
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs, isEmpty);
      expect(find.text('Vigência da ficha'), findsNothing);
    });

    testWidgets('renovar pelo menu da própria ficha registra origem ficha', (tester) async {
      final cena = await _abrir(tester, _ficha());
      await tester.tap(find.text('Vigência'));
      await _settle(tester);
      await tester.tap(find.text('Renovar por 12 semanas'));
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs.single, contains('origem: ficha'));
      expect(cena.logs.single, contains('semanas: 12'));
    });

    testWidgets('se a renovação falhar, nada é registrado', (tester) async {
      final cena = await _abrir(tester, _ficha(), abrirVigencia: true, origem: 'aviso', falhar: true);
      await tester.tap(find.text('Renovar por 8 semanas'));
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs, isEmpty);
    });
  });

  group('vigência definida', () {
    testWidgets('criar a ficha com "Vale por" registra criação e as semanas', (tester) async {
      final cena = await _abrir(tester, RotinaFila.vazia);
      await tester.tap(find.text('12 semanas'));
      await _settle(tester);
      await tester.tap(find.text('4'));
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs.single, contains('ficha_vigencia_definida'));
      expect(cena.logs.single, contains('origem: criacao'));
      expect(cena.logs.single, contains('semanas: 12'));
    });

    testWidgets('criar sem prazo não registra vigência', (tester) async {
      final cena = await _abrir(tester, RotinaFila.vazia);
      await tester.tap(find.text('Sem prazo'));
      await _settle(tester);
      await tester.tap(find.text('3'));
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs, isEmpty);
    });

    testWidgets('aplicar um modelo registra origem modelo com 8 semanas', (tester) async {
      final cena = await _abrir(tester, _ficha());
      await tester.tap(find.byTooltip('Opções da ficha'));
      await _settle(tester);
      await tester.tap(find.text('Aplicar modelo'));
      await _settle(tester);
      await tester.tap(find.text('Hipertrofia 4 dias'));
      await _settle(tester);
      await tester.tap(find.text('Manter as cargas'));
      await _settle(tester);
      await tester.tap(find.text('Aplicar modelo').last);
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs.single, contains('origem: modelo'));
      expect(cena.logs.single, contains('semanas: 8'));
    });

    testWidgets('duplicar como base registra origem ficha com 8 semanas', (tester) async {
      final cena = await _abrir(tester, _ficha());
      await tester.tap(find.byTooltip('Opções da ficha'));
      await _settle(tester);
      await tester.tap(find.text('Duplicar como base'));
      await _settle(tester);
      await tester.tap(find.text('Manter as cargas'));
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs.single, contains('origem: ficha'));
      expect(cena.logs.single, contains('semanas: 8'));
    });

    testWidgets('se a gravação falhar, a vigência não é registrada', (tester) async {
      final cena = await _abrir(tester, RotinaFila.vazia, falhar: true);
      await tester.tap(find.text('4'));
      await _settle(tester);
      cena.restaurar();

      expect(cena.logs, isEmpty);
    });
  });
}
