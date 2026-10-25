@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/hoje_personal_harness.dart';
import '../../support/tolerant_golden_comparator.dart';

FilaAcaoResumo _fila({
  required String tipo,
  required String chave,
  required String titulo,
  required String descricao,
  required String url,
  String prioridade = 'P0',
  String cta = '',
}) => FilaAcaoResumo(
  tipo: tipo,
  actionKey: chave,
  titulo: titulo,
  descricao: descricao,
  acaoUrl: url,
  prioridade: prioridade,
  severidade: 'ALTA',
  responsavel: 'Personal',
  sla: 'Hoje',
  status: 'ABERTO',
  ctaLabel: cta,
  iaSugerida: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DashboardHomeClientCache.clear();
  });

  final casos = <String, DashboardHomeBundle Function()>{
    'cheia': () => hojeBundle(
      risco: [
        AlertaResumo(id: 1, nomeAluno: 'Hugo Silva', motivo: '9 dias sem treinar', nivelRisco: 'ALTO'),
        AlertaResumo(id: 2, nomeAluno: 'Bia Lima', motivo: '7 dias sem treinar', nivelRisco: 'MEDIO'),
      ],
      cobrancas: [
        MensalidadeResumo(id: 1, nomeAluno: 'Ana Souza', valor: 150, dataVencimento: '2026-10-01', diasAtraso: 3),
      ],
      fila: [
        _fila(
          tipo: 'FICHA',
          chave: 'FICHA_VENCENDO_4',
          titulo: 'Renovar a ficha de Pedro Alves',
          descricao: 'Vence hoje',
          url: '/alunos/4/rotina?renovar=1&origem=hoje',
          cta: 'Renovar',
        ),
      ],
      agenda: [
        AgendamentoResumo(id: 1, nomeAluno: 'Carla Dias', horario: '09:00', status: 'CONFIRMADO'),
        AgendamentoResumo(id: 2, nomeAluno: 'Bruno Costa', horario: '14:00', status: 'AGENDADO'),
      ],
      mensagens: 2,
      checkins: 3,
      receita: 1200,
      inadimplentes: 1,
    ),
    'quieta': () => hojeBundle(),
    'nova': () => hojeBundle(totalAlunos: 0, onboardingCompleto: false),
  };

  for (final escuro in [false, true]) {
    for (final entry in casos.entries) {
      testWidgets('Hoje do personal, ${entry.key} (escuro: $escuro)', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 1500));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(hojeApp(entry.value(), escuro: escuro));
        await assentarHoje(tester);
        await expectFocuxGolden(
          find.byKey(const ValueKey('tela')),
          'goldens/hoje_personal_${entry.key}_390${escuro ? '_dark' : ''}.png',
        );
        // Sem backend no teste, o ApiClient tenta de novo com espera: deixa esgotar.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(seconds: 5));
        }
      });
    }
  }
}
