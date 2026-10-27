@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/checkin/widgets/ficha_vigencia_aluno.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/features/dashboard/screens/aluno_ferramentas_screen.dart';
import 'package:focux_app/features/dashboard/screens/perfil_aluno_screen.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_semana_faixa.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_proximos_passos.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_today_focus_card.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/utils/ficha_vigencia.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/tolerant_golden_comparator.dart';

// 28/10/2026 é quarta-feira.
final _hoje = DateTime(2026, 10, 28, 12);

Widget _app(Widget home, {bool escuro = false, List<Override> overrides = const []}) =>
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

Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _drenar(WidgetTester tester) async {
  // Sem backend no teste, o ApiClient tenta de novo com espera: deixa esgotar.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(seconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final rotina = RotinaFila(
    itens: const [
      RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 1, nome: 'Peito', diaSemana: 1),
      RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 2, nome: 'Costas', diaSemana: 3),
      RotinaItem(id: 3, tipo: RotinaItemTipo.treino, treinoId: 3, nome: 'Pernas', diaSemana: 5),
    ],
    vigencia: VigenciaFicha(fim: DateTime(2026, 11, 2)),
    atualizadaEm: DateTime(2026, 10, 27, 9),
  );

  for (final escuro in [false, true]) {
    testWidgets('Hoje do aluno, blocos novos (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AlunoTodayFocusCard(
                    action: const AlunoTodayAction(
                      mode: AlunoTodayMode.descansoHoje,
                      route: '/checkin/executar',
                      treinoNome: 'Treino Força',
                    ),
                    hoje: _hoje,
                    isDark: escuro,
                    onAction: () {},
                    semana: faixaDaSemana(rotina, const [], _hoje),
                    seloFicha: 'Até 02/11',
                  ),
                  const SizedBox(height: 12),
                  FichaVigenciaAluno(rotina: rotina, hoje: _hoje),
                  const SizedBox(height: 16),
                  AlunoProximosPassos(
                    hoje: _hoje,
                    resto: 1,
                    onVerMais: () {},
                    onTap: (_) {},
                    pendencias: const [
                      AlunoPendencia(AlunoPendenciaTipo.medida, primeiraVez: true),
                      AlunoPendencia(AlunoPendenciaTipo.perfil),
                      AlunoPendencia(AlunoPendenciaTipo.chat, quantidade: 2),
                    ],
                  ),
                ],
              ),
            ),
          ),
          escuro: escuro,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await expectFocuxGolden(
        find.byKey(const ValueKey('tela')),
        'goldens/aluno_hoje_blocos_390${escuro ? '_dark' : ''}.png',
      );
    });
  }

  final aluno = Aluno(
    id: 7,
    nome: 'Matheus aluno',
    email: 'matheus@focux.test',
    status: 'ATIVO',
    objetivo: 'Hipertrofia',
  );

  for (final escuro in [false, true]) {
    testWidgets('Perfil do aluno, 57% (escuro: $escuro)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          const PerfilAlunoScreen(),
          escuro: escuro,
          overrides: [
            alunoPerfilHomeProvider.overrideWith(
              (ref) async => AlunoPerfilHomeBundle(
                aluno: aluno,
                medidas: const [],
                completionPercent: 57,
              ),
            ),
          ],
        ),
      );
      await _assentar(tester);
      await expectFocuxGolden(
        find.byKey(const ValueKey('tela')),
        'goldens/aluno_perfil_57_390${escuro ? '_dark' : ''}.png',
      );
      await _drenar(tester);
    });
  }

  testWidgets('Ferramentas do aluno (claro)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        const AlunoFerramentasScreen(),
        overrides: [
          alunoDashboardHomeProvider.overrideWith(
            (ref) async => AlunoDashboardHomeBundle.fromJson({
              'aluno': {'id': 7, 'nome': 'Ana', 'email': 'a@t.com', 'status': 'ATIVO'},
              'personalBrand': {'nomePersonal': 'Carlos', 'plano': 'PRO'},
              'treinos': [],
              'historicoResumo': [],
              'medidas': [],
              'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
            }),
          ),
        ],
      ),
    );
    await _assentar(tester);
    await expectFocuxGolden(
      find.byKey(const ValueKey('tela')),
      'goldens/aluno_ferramentas_390.png',
    );
    await _drenar(tester);
  });
}
