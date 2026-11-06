import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/dashboard_provider.dart';
import '../../financeiro/providers/financeiro_provider.dart';
import '../data/aluno_repository.dart';
import 'alunos_provider.dart';

/// Ação em vários alunos: quantos deram certo e o primeiro erro.
class ResultadoLoteAlunos {
  const ResultadoLoteAlunos({
    required this.total,
    required this.sucesso,
    this.primeiroErro,
    this.primeiroStack,
  });

  final int total;
  final int sucesso;
  final Object? primeiroErro;
  final StackTrace? primeiroStack;

  int get falhas => total - sucesso;
}

/// Ciclo de vida do Aluno pela carteira (lista e ficha): excluir, mudar status
/// e marcar mensalidades pagas. Dono das chamadas e do que fica velho depois:
/// Alunos Home, 360, Copiloto, a Home do personal e o Financeiro.
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
    StackTrace? primeiroStack;
    for (final id in ids) {
      try {
        await _repo.excluirAluno(id);
        sucesso++;
      } catch (e, st) {
        primeiroErro ??= e;
        primeiroStack ??= st;
      }
    }
    _carteiraMudou();
    return ResultadoLoteAlunos(
      total: ids.length,
      sucesso: sucesso,
      primeiroErro: primeiroErro,
      primeiroStack: primeiroStack,
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

  /// A carteira mudou de verdade (não só recarregou): além dos caches de
  /// alunos, caem a Home do personal (contagens) e o Financeiro (cobranças e
  /// inadimplência do aluno excluído, bloqueado ou pago).
  void _carteiraMudou() {
    _ref.read(limparCachesDeAlunosProvider)();
    invalidatePersonalDashboardHomeRef(_ref);
    _ref.invalidate(financeiroHomeProvider);
  }
}

final alunoCicloDeVidaProvider = Provider<AlunoCicloDeVida>(
  AlunoCicloDeVida.new,
);
