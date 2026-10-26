@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_resumo_tab.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/utils/ficha_vigencia.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/tolerant_golden_comparator.dart';

const _id = 42;

// 28/10/2026 é quarta-feira.
final _hoje = DateTime(2026, 10, 28, 12);

final _proxima = ProximaAcaoResumo(
  acao: 'Completar mapa corporal',
  motivo: 'Faltam medidas para ajustar o treino',
  fonte: 'PADRAO',
  prioridade: 'P2',
);

final _ficha = RotinaFila(
  itens: const [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 1, nome: 'Treino A', diaSemana: 1),
    RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 2, nome: 'Treino B', diaSemana: 3),
    RotinaItem(id: 3, tipo: RotinaItemTipo.treino, treinoId: 3, nome: 'Treino C', diaSemana: 5),
  ],
  vigencia: VigenciaFicha(fim: DateTime(2026, 11, 2)),
);

Widget _app(Widget home, {required bool escuro, List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        theme: escuro
            ? AppTheme.buildDarkTheme(EagleTokens.brand)
            : AppTheme.buildTheme(EagleTokens.brand),
        home: RepaintBoundary(key: const ValueKey('tela'), child: home),
      ),
    );

List<Override> _overrides(Aluno aluno, RotinaFila rotina) => [
  aluno360OperacaoProvider(_id).overrideWith(
    (ref) => resolveAluno360OperacaoSnapshot(
      aluno: aluno,
      proximaAcao360: _proxima,
      forceIa: false,
      iaAsync: null,
      hasOpenTask: false,
      followUpDue: false,
      wearableRelevant: false,
    ),
  ),
  alunoRotinaProvider(_id).overrideWith((ref) async => rotina),
];

Widget _tab(Aluno aluno) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Aluno360ResumoTab(
      aluno: aluno,
      alunoId: _id,
      isDark: false,
      primary: EagleTokens.brand,
      proximaAcao360: _proxima,
      hasOpenCopilotTask360: false,
      aderenciaSemanal: null,
      recoveryAsync: const AsyncData(null),
      autonomiaResumoAsync: const AsyncLoading(),
      hoje: _hoje,
    ),
  ),
);

Aluno _aluno({
  required String nome,
  bool emRisco = false,
  int? dias,
  int? ader,
  bool inadimplente = false,
}) => Aluno(
  id: _id,
  nome: nome,
  email: 'a@x.com',
  status: 'ATIVO',
  emRisco: emRisco,
  riscoNivel: emRisco ? 'ALTO' : 'BAIXO',
  diasSemTreino: dias,
  aderenciaPercent: ader,
  inadimplente: inadimplente,
  statusFinanceiro: inadimplente ? 'INADIMPLENTE' : 'EM_DIA',
);

Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  final casos = <String, Aluno>{
    'contato': _aluno(nome: 'Hugo', emRisco: true, dias: 9, ader: 12),
    'novo': _aluno(nome: 'Bia', emRisco: true, ader: 0),
    'financeiro': _aluno(nome: 'Caio', dias: 1, ader: 80, inadimplente: true),
  };

  for (final escuro in [false, true]) {
    for (final e in casos.entries) {
      testWidgets('Resumo do aluno, ${e.key} (escuro: $escuro)', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _app(_tab(e.value), escuro: escuro, overrides: _overrides(e.value, _ficha)),
        );
        await _assentar(tester);
        await expectFocuxGolden(
          find.byKey(const ValueKey('tela')),
          'goldens/aluno360_resumo_${e.key}_390${escuro ? '_dark' : ''}.png',
        );
      });
    }
  }
}
