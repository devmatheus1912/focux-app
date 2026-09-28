import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_dashboard_home_client_cache.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';

void main() {
  setUp(DashboardHomeClientCache.clear);

  DashboardHomeBundle sampleBundle() => DashboardHomeBundle(
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
    final bundle = sampleBundle();
    final t0 = DateTime(2026, 8, 16, 12);
    DashboardHomeClientCache.put(bundle, now: t0);
    expect(
      DashboardHomeClientCache.getIfFresh(
        now: t0.add(const Duration(seconds: 89)),
      ),
      isNotNull,
    );
    expect(
      DashboardHomeClientCache.getIfFresh(
        now: t0.add(const Duration(seconds: 91)),
      ),
      isNull,
    );
  });

  test('SWR: stale até 5min + claimRefresh single-flight', () {
    final t0 = DateTime(2026, 9, 18, 12);
    DashboardHomeClientCache.put(sampleBundle(), now: t0);
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

  group('AlunoDashboardHomeClientCache.revalidar', () {
    tearDown(AlunoDashboardHomeClientCache.clear);

    test('304 renova a idade e devolve cópia nova', () {
      final t0 = DateTime(2026, 9, 27, 8);
      final bundle = AlunoDashboardHomeBundle.fromJson({
        'aluno': {
          'id': 7,
          'nome': 'Ana',
          'email': 'ana@focux.test',
          'status': 'ATIVO',
        },
        'streakAtual': 3,
      });
      AlunoDashboardHomeClientCache.put(bundle, now: t0);
      final t1 = t0.add(const Duration(minutes: 2));
      final novo = AlunoDashboardHomeClientCache.revalidar(now: t1)!;
      expect(identical(novo, bundle), isFalse);
      expect(novo.fetchedAt, t1);
      expect(novo.aluno.nome, 'Ana');
      expect(novo.streakAtual, 3);
      expect(AlunoDashboardHomeClientCache.fetchedAt, t1);
      expect(
        AlunoDashboardHomeClientCache.getIfFresh(
          now: t1.add(const Duration(seconds: 30)),
        ),
        same(novo),
      );
    });

    test('sem bundle → null', () {
      expect(AlunoDashboardHomeClientCache.revalidar(), isNull);
    });
  });
}
