import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_ciclo_de_vida_provider.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';

class _RepoFake extends AlunoRepository {
  _RepoFake({this.falham = const {}}) : super.dio(Dio());

  final Set<int> falham;
  final excluidos = <int>[];
  final chamadas = <String>[];

  @override
  Future<void> excluirAluno(int id) async {
    if (falham.contains(id)) throw StateError('falhou $id');
    excluidos.add(id);
  }

  @override
  Future<void> atualizarStatusLote(List<int> ids, String status) async {
    chamadas.add('status:$status:$ids');
  }

  @override
  Future<void> marcarMensalidadesPagasLote(List<int> ids) async {
    chamadas.add('pagas:$ids');
  }
}

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

void main() {
  ProviderContainer container(_RepoFake repo) {
    final c = ProviderContainer(
      overrides: [alunoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    dashboardHomeClientCache.put(_bundle());
  });

  tearDown(dashboardHomeClientCache.clear);

  test(
    'excluir segue depois de uma falha e conta o resultado parcial',
    () async {
      final repo = _RepoFake(falham: {2});
      final r = await container(
        repo,
      ).read(alunoCicloDeVidaProvider).excluir([1, 2, 3]);

      expect(repo.excluidos, [1, 3]);
      expect(r.total, 3);
      expect(r.sucesso, 2);
      expect(r.falhas, 1);
      expect(r.primeiroErro, isA<StateError>());
    },
  );

  test('qualquer mudança na carteira derruba a Home do personal', () async {
    final repo = _RepoFake();
    final ciclo = container(repo).read(alunoCicloDeVidaProvider);

    await ciclo.atualizarStatus([4], 'BLOQUEADO');
    expect(dashboardHomeClientCache.hasBody, isFalse);

    dashboardHomeClientCache.put(_bundle());
    await ciclo.marcarMensalidadesPagas([4, 5]);
    expect(dashboardHomeClientCache.hasBody, isFalse);
    expect(repo.chamadas, ['status:BLOQUEADO:[4]', 'pagas:[4, 5]']);
  });
}
