import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';

void main() {
  setUp(DashboardHomeClientCache.clear);

  DashboardHomeBundle _bundle() => DashboardHomeBundle(
    personal: DashboardData(
      totalAlunos: 1,
      alunosAtivos: 1,
      planoAtual: 'FREE',
      limiteAlunos: 3,
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
      receitaMes: 0,
      receitaAcumulada: 0,
      ticketMedio: 0,
      totalInadimplentes: 0,
      previsaoReceita: 0,
      vencimentosProximos: const [],
      topAlunos: const [],
      evolucaoMensal: const [],
    ),
  );

  test('TTL 90s alinhado ao BE dashboard-home', () {
    final bundle = _bundle();
    final t0 = DateTime(2026, 8, 16, 12);
    DashboardHomeClientCache.put(bundle, now: t0);
    expect(
      DashboardHomeClientCache.getIfFresh(now: t0.add(const Duration(seconds: 89))),
      isNotNull,
    );
    expect(
      DashboardHomeClientCache.getIfFresh(now: t0.add(const Duration(seconds: 91))),
      isNull,
    );
  });

  test('SWR: stale até 5min + claimRefresh single-flight', () {
    final t0 = DateTime(2026, 9, 18, 12);
    DashboardHomeClientCache.put(_bundle(), now: t0);
    expect(
      DashboardHomeClientCache.getEvenIfStale(
        now: t0.add(const Duration(minutes: 2)),
      ),
      isNotNull,
    );
    expect(DashboardHomeClientCache.claimRefresh(), isTrue);
    expect(DashboardHomeClientCache.claimRefresh(), isFalse);
    DashboardHomeClientCache.releaseRefresh();
    expect(DashboardHomeClientCache.claimRefresh(), isTrue);
    DashboardHomeClientCache.clear();
    expect(
      DashboardHomeClientCache.getEvenIfStale(
        now: t0.add(const Duration(minutes: 2)),
      ),
      isNull,
    );
  });
}
