import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focux_app/core/auth/session_invalidator.dart';
import 'package:focux_app/features/agenda/utils/agenda_week_client_cache.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_followup_store.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_client_cache.dart';
import 'package:focux_app/features/alunos/utils/alunos_home_client_cache.dart';
import 'package:focux_app/features/checkin/data/meus_treinos_mem_cache.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/exercicios/data/biblioteca_wizard_draft.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/growth/data/migracao_magica_draft_cache.dart';
import 'package:focux_app/features/growth/utils/migracao_magica_display.dart';
import 'package:focux_app/features/onboarding/data/onboarding_repository.dart';
import 'package:focux_app/features/onboarding/data/onboarding_wizard_client_cache.dart';
import 'package:focux_app/features/planos/data/plano_features_bff_cache.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    SessionInvalidator.clearTenantMemoryCaches();
  });

  tearDown(SessionInvalidator.clearTenantMemoryCaches);

  AlunosHomeBundle alunosHome() => AlunosHomeBundle(
    alunos: [
      Aluno(
        id: 7,
        nome: 'Ana Tenant A',
        email: 'ana@tenant-a.test',
        status: 'ATIVO',
        telefone: '11999999999',
        whatsapp: '11999999999',
      ),
    ],
    stats: const AlunosStats(
      total: 1,
      totalAtivos: 1,
      totalInadimplentes: 0,
      totalRiscoAlto: 0,
      totalConvites: 0,
    ),
    alertasConfig: AlertasConfiguracao(
      diasSemTreino: 7,
      aderenciaMinima: 50,
    ),
  );

  DashboardHomeBundle dashboardHome() => DashboardHomeBundle(
    personal: DashboardData(
      totalAlunos: 1,
      alunosAtivos: 1,
      planoAtual: 'PRO',
      limiteAlunos: 50,
    ),
    commandCenter: CommandCenterData(
      agendaHoje: const [],
      alunosEmRisco: const [],
      alunosScore: const [],
      cobrancasPendentes: const [],
      autonomiaGargalos: const [],
      modoOperacao: const [],
      filaAcoes: const [],
    ),
    financeiro: FinanceiroDashboard(
      receitaMes: 1200,
      receitaAcumulada: 1200,
      ticketMedio: 1200,
      totalInadimplentes: 0,
      previsaoReceita: 1200,
      vencimentosProximos: const [],
      topAlunos: const [],
      evolucaoMensal: const [],
    ),
  );

  test('invalidate drops in-memory tenant PII so the next account cannot read it',
      () async {
    const query = AlunosHomeQuery();
    final now = DateTime(2026, 9, 10, 12);
    AlunosHomeClientCache.put(query, alunosHome(), now: now);
    DashboardHomeClientCache.put(dashboardHome(), now: now);
    Aluno360ClientCache.putOperacao(
      7,
      Aluno360Operacao(
        aluno: alunosHome().alunos.first,
        autonomiaResumo: const AlunoAutonomiaResumo(
          alunoId: 7,
          totalEventos: 1,
          vistos: 0,
          cliques: 0,
          concluidos: 0,
        ),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Contatar',
          motivo: 'Sumiu',
          fonte: 'PADRAO',
          prioridade: 'P1',
        ),
      ),
      now: now,
    );
    PlanoFeaturesBffCache.put(
      const PlanoFeatures(
        plano: SubscriptionPlan.PRO,
        financeiro: true,
        agenda: true,
        relatorios: true,
        whiteLabel: false,
        iaCopiloto: true,
        migracaoFoto: true,
      ),
      now: now,
    );
    OnboardingWizardClientCache.put(
      OnboardingWizard(
        steps: const [],
        completedCount: 1,
        totalCount: 7,
        progressPercent: 14,
        nextActionLabel: 'Perfil',
        nextActionRoute: '/perfil/editar',
        wizardCompleto: false,
        allStepsDone: false,
      ),
      now: now,
    );
    AgendaWeekClientCache.put('2026-09-07', const []);
    BibliotecaWizardDraftCache.put(
      const BibliotecaWizardDraft(
        step: 1,
        modalidades: <Modalidade>{},
        espacos: <Espaco>{},
      ),
    );
    MeusTreinosMemCache.save(const []);

    await MigracaoMagicaDraftCache.save(
      text: 'Ana, ana@tenant-a.test, 11999999999',
      fonte: MigracaoFonte.texto,
    );
    await AlunoFollowUpStore.snooze(7);
    final prefsBefore = await SharedPreferences.getInstance();
    await prefsBefore.setBool('health_authorized', true);
    expect(prefsBefore.getBool('health_authorized'), isTrue);

    expect(AlunosHomeClientCache.getIfFresh(query, now: now), isNotNull);
    expect(DashboardHomeClientCache.getIfFresh(now: now), isNotNull);
    expect(Aluno360ClientCache.getOperacaoIfFresh(7, now: now), isNotNull);
    expect(PlanoFeaturesBffCache.getIfFresh(now: now), isNotNull);
    expect(OnboardingWizardClientCache.getIfFresh(now: now), isNotNull);
    expect(AgendaWeekClientCache.get('2026-09-07'), isNotNull);
    expect(BibliotecaWizardDraftCache.get(), isNotNull);
    expect(MeusTreinosMemCache.loadIfFresh(), isNotNull);
    expect(await MigracaoMagicaDraftCache.load(), isNotNull);
    expect(await AlunoFollowUpStore.loadAll(), isNotEmpty);

    await SessionInvalidator.invalidate(reason: 'test');

    expect(AlunosHomeClientCache.getIfFresh(query, now: now), isNull);
    expect(DashboardHomeClientCache.getIfFresh(now: now), isNull);
    expect(Aluno360ClientCache.getOperacaoIfFresh(7, now: now), isNull);
    expect(Aluno360ClientCache.getOperacaoEvenIfStale(7, now: now), isNull);
    expect(PlanoFeaturesBffCache.getIfFresh(now: now), isNull);
    expect(OnboardingWizardClientCache.getIfFresh(now: now), isNull);
    expect(AgendaWeekClientCache.get('2026-09-07'), isNull);
    expect(BibliotecaWizardDraftCache.get(), isNull);
    expect(MeusTreinosMemCache.loadIfFresh(), isNull);
    expect(await MigracaoMagicaDraftCache.load(), isNull);
    expect(await AlunoFollowUpStore.loadAll(), isEmpty);
    final prefsAfter = await SharedPreferences.getInstance();
    expect(prefsAfter.getBool('health_authorized'), isNull);
  });
}
