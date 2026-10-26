import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_detail_ferramentas_tab.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_timeline_card.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/riverpod_seeds.dart';

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

Override _proPlanoOverride() =>
    seededPlanoFeatures(PlanoFeatures.optimisticEnterprise);

Widget _harness({
  required List<Override> overrides,
  required Widget child,
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
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

      expect(find.byKey(const ValueKey('aluno360_ferramentas_grupos')), findsOneWidget);
      expect(find.text('Dados do aluno'), findsOneWidget);
      expect(find.text('Composição corporal'), findsOneWidget);
      expect(find.text('Mais ferramentas'), findsNothing);
      expect(find.text('Atalhos do aluno'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
