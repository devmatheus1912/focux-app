import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/dashboard_provider.dart';
import '../../ia/providers/ia_copilot_providers.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_client_cache.dart';
import '../utils/alunos_home_client_cache.dart';
import 'alunos_provider.dart';

/// Ação em vários alunos: quantos deram certo e o primeiro erro.
class ResultadoLoteAlunos {
  const ResultadoLoteAlunos({
    required this.total,
    required this.sucesso,
    this.primeiroErro,
  });

  final int total;
  final int sucesso;
  final Object? primeiroErro;

  int get falhas => total - sucesso;
}

/// Ciclo de vida do Aluno pela carteira (lista e ficha): excluir, mudar status
/// e marcar mensalidades pagas. Dono das chamadas e do que fica velho depois:
/// Alunos Home, 360, Copiloto e a Home do personal (contagens da carteira).
/// As telas ficam só com a confirmação e o aviso.
class AlunoCicloDeVida {
  AlunoCicloDeVida(this._ref);

  final Ref _ref;

  AlunoRepository get _repo => _ref.read(alunoRepositoryProvider);

  /// Exclui um por um; falha de um não para os outros. Limpa as Homes mesmo
  /// com falha parcial (os que saíram já não existem).
  Future<ResultadoLoteAlunos> excluir(List<int> ids) async {
    var sucesso = 0;
    Object? primeiroErro;
    for (final id in ids) {
      try {
        await _repo.excluirAluno(id);
        sucesso++;
      } catch (e) {
        primeiroErro ??= e;
      }
    }
    _carteiraMudou();
    return ResultadoLoteAlunos(
      total: ids.length,
      sucesso: sucesso,
      primeiroErro: primeiroErro,
    );
  }

  Future<void> atualizarStatus(List<int> ids, String status) async {
    await _repo.atualizarStatusLote(ids, status);
    _carteiraMudou();
  }

  Future<void> marcarMensalidadesPagas(List<int> ids) async {
    await _repo.marcarMensalidadesPagasLote(ids);
    _carteiraMudou();
  }

  void _carteiraMudou() {
    AlunosHomeClientCache.clear();
    Aluno360ClientCache.clear();
    _ref.read(alunosHomeTailProvider.notifier).clear();
    _ref.invalidate(alunosHomeProvider);
    _ref.invalidate(iaCopilotoHomeProvider);
    invalidatePersonalDashboardHomeRef(_ref);
  }
}

final alunoCicloDeVidaProvider = Provider<AlunoCicloDeVida>(
  AlunoCicloDeVida.new,
);
