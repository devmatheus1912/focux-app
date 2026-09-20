import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/widgets/operational_metric_tile.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_detail_ferramentas_tab.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_operacao_sticky_cta.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_operational_status_section.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_timeline_card.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke 360 sem [AlunoDetailScreen]: tela cheia + GoRouter travava o suite
/// no CI (`Cannot close sink while adding stream` / cancel).
const _alunoId = 42;

final _aluno = Aluno(
  id: _alunoId,
  nome: 'Ana Silva',
  email: 'ana@test.com',
  status: 'ATIVO',
  scoreProntidao: 82,
  aderenciaPercent: 74,
  diasSemTreino: 2,
  riscoNivel: 'BAIXO',
  proximoContato: '2026-06-10',
  dataNascimento: '1995-03-15',
  altura: 1.68,
  objetivo: 'Hipertrofia',
);

final _proximaAcao = ProximaAcaoResumo(
  acao: 'Enviar mensagem de follow-up',
  motivo: 'Contato pendente',
  fonte: 'PADRAO',
  prioridade: 'P2',
  tipoAcao: 'CONTATO',
  mensagemSugerida: 'Oi, Ana.',
);

final _emptyEvolucao = EvolucaoInteligente(
  sinal: 'SEM_DADOS',
  resumo: '',
  volumeSemanal: 0,
  volumeMensal: 0,
  proximaAcao: '',
  sugerirCopiloto: false,
);

List<Map<String, dynamic>> _week() {
  final anchor = DateTime(2026, 6, 7);
  return List.generate(7, (i) {
    final day = anchor.subtract(Duration(days: 6 - i));
    final iso =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return {'data': iso, 'checkins': i.isEven ? 1 : 0};
  });
}

Override _proPlanoOverride() {
  final notifier = PlanoFeaturesNotifier(PlanosRepository(ApiClient()));
  notifier.seedFromHome(PlanoFeatures.optimisticEnterprise);
  return planoFeaturesProvider.overrideWith((ref) => notifier);
}

Widget _harness({
  required List<Override> overrides,
  required Widget child,
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 1600),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
          accessibleNavigation: true,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  for (final scale in [1.0, 1.25]) {
    testWidgets('Operação status + sticky CTA at textScaler $scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          textScale: scale,
          overrides: [
            aluno360OperacaoProvider(_alunoId).overrideWith(
              (ref) => resolveAluno360OperacaoSnapshot(
                aluno: _aluno,
                proximaAcao360: _proximaAcao,
                forceIa: false,
                iaAsync: null,
                hasOpenTask: false,
                followUpDue: false,
                wearableRelevant: false,
              ),
            ),
            alunoOpenIaActionsProvider(_alunoId)
                .overrideWith((ref) async => const []),
            alunoRecoveryProvider(_alunoId).overrideWith((ref) async => null),
            alunoCopilotoForceIaProvider(_alunoId).overrideWith((ref) => false),
          ],
          child: Column(
            children: [
              Aluno360OperationalStatusSection(
                aluno: _aluno,
                alunoId: _alunoId,
                isDark: false,
                primary: const Color(0xFF12A3A3),
                aderenciaSemanal: _week(),
              ),
              Aluno360OperacaoStickyCtaBar(
                aluno: _aluno,
                alunoId: _alunoId,
                proximaAcao360: _proximaAcao,
                hasOpenCopilotTask360: false,
                isDark: false,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('aluno360_operacao_status')), findsOneWidget);
      expect(find.text('Status operacional'), findsOneWidget);
      expect(find.byType(OperationalMetricTile), findsWidgets);
      expect(find.byKey(const ValueKey('aluno360_operacao_sticky_cta')), findsOneWidget);
      expect(find.text('Enviar mensagem'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('contact priority keeps operational status visible', (tester) async {
    final beatriz = Aluno(
      id: 7,
      nome: 'Beatriz',
      email: 'beatriz@test.com',
      status: 'ATIVO',
      emRisco: true,
      riscoNivel: 'ALTO',
      aderenciaPercent: 0,
      diasSemTreino: 14,
      objetivo: 'Hipertrofia',
    );
    final p1 = ProximaAcaoResumo(
      acao: 'Retomar contato com Beatriz',
      motivo: 'Sem check-ins recentes',
      fonte: 'PADRAO',
      prioridade: 'P1',
      tipoAcao: 'CONTATO',
      mensagemSugerida: 'Oi, Beatriz.',
    );

    await tester.pumpWidget(
      _harness(
        overrides: [
          aluno360OperacaoProvider(7).overrideWith(
            (ref) => resolveAluno360OperacaoSnapshot(
              aluno: beatriz,
              proximaAcao360: p1,
              forceIa: false,
              iaAsync: null,
              hasOpenTask: false,
              followUpDue: true,
              wearableRelevant: false,
            ),
          ),
          alunoOpenIaActionsProvider(7).overrideWith((ref) async => const []),
          alunoRecoveryProvider(7).overrideWith((ref) async => null),
          alunoCopilotoForceIaProvider(7).overrideWith((ref) => false),
        ],
        child: Column(
          children: [
            Text(copilotCardTitle(contactPriority: true)),
            Aluno360OperationalStatusSection(
              aluno: beatriz,
              alunoId: 7,
              isDark: false,
              primary: const Color(0xFF12A3A3),
              aderenciaSemanal: _week(),
            ),
            Aluno360OperacaoStickyCtaBar(
              aluno: beatriz,
              alunoId: 7,
              proximaAcao360: p1,
              hasOpenCopilotTask360: false,
              isDark: false,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Prioridade do dia'), findsOneWidget);
    expect(find.byKey(const ValueKey('aluno360_operacao_status')), findsOneWidget);
    expect(find.text('Status operacional'), findsOneWidget);
  });

  testWidgets('Evolução empty state shows actionable CTAs', (tester) async {
    await tester.pumpWidget(
      _harness(
        overrides: const [],
        child: Column(
          children: [
            Aluno360EvolucaoInteligenteCard(
              alunoId: _alunoId,
              alunoNome: _aluno.nome,
              evolucaoAsync: AsyncData(_emptyEvolucao),
              isDark: false,
            ),
            Aluno360TimelineCard(
              aluno: _aluno,
              timelineApiAsync: const AsyncData([]),
              isDark: false,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('aluno360_evolucao_empty')), findsOneWidget);
    expect(find.text('Pedir check-in'), findsWidgets);
    expect(find.text('Abrir chat'), findsWidgets);
    expect(find.byKey(const ValueKey('aluno360_timeline_empty')), findsOneWidget);
  });

  for (final scale in [1.0, 1.25, 1.3]) {
    testWidgets('Ferramentas tab modules grid at textScaler $scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          textScale: scale,
          overrides: [
            _proPlanoOverride(),
            aluno360FerramentasBundleProvider(_alunoId).overrideWith(
              (ref) async => const Aluno360Ferramentas(),
            ),
            alunoAderenciaSemanalProvider(_alunoId).overrideWith(
              (ref) async => _week(),
            ),
          ],
          child: Aluno360DetailFerramentasTab(
            aluno: _aluno,
            alunoId: _alunoId,
            isDark: false,
            primary: const Color(0xFF12A3A3),
            perfilCompletion: 80,
            animateEntrance: false,
            onEntrancePlayed: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('aluno360_ferramentas_modulos')), findsOneWidget);
      expect(find.text('Medidas'), findsOneWidget);
      expect(find.text('Idade'), findsOneWidget);
      expect(find.text('Gordura corporal'), findsOneWidget);
      expect(find.text('Composição corporal'), findsOneWidget);
      expect(find.text('Atalhos do aluno'), findsOneWidget);
      expect(find.text('Mais ferramentas'), findsOneWidget);
      expect(find.text('Gordura'), findsNothing);
      expect(find.text('Massa magra'), findsOneWidget);
      expect(find.text('Registrar'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
