import '../data/checkin_repository.dart';
import '../data/checkin_series_pendentes.dart';
import 'checkin_execucao_estado.dart';
import 'checkin_series_fila.dart';

/// Sessão vista pela tela: a execução já com as séries da fila e quantas
/// séries ainda esperam envio.
class CheckinSessaoEstado {
  const CheckinSessaoEstado({required this.execucao, required this.pendentes});

  final ExecucaoTreino? execucao;
  final int pendentes;
}

/// Sessão concluída: a execução final (ou a última que se conseguiu ler) e a
/// evolução da sessão, quando o servidor respondeu.
class CheckinConclusao {
  const CheckinConclusao({required this.concluida, this.evolucao});

  final ExecucaoTreino? concluida;
  final SessaoEvolucaoDto? evolucao;
}

/// Ordem das idas ao servidor de uma sessão de treino, sem tela:
/// carregar já com as séries pendentes da fila offline, somar o que a fila
/// enviou, voltar ao servidor quando uma série é recusada e concluir mesmo
/// depois de timeout. A tela cuida só de flags, relógios e avisos.
class CheckinSessao {
  const CheckinSessao({
    required this.repo,
    required this.fila,
    required this.enviarFila,
  });

  final CheckinRepository repo;
  final CheckinSeriesPendentesStore fila;
  final Future<CheckinFilaResultado> Function() enviarFila;

  /// Abre (ou retoma) a sessão do treino e aplica o que está na fila.
  Future<CheckinSessaoEstado> iniciar(int treinoId) async {
    final recebida = await repo.iniciar(treinoId);
    final pendentes = await fila.ler();
    final execucao = checkinAplicarPendentes(recebida, pendentes);
    return CheckinSessaoEstado(
      execucao: execucao,
      pendentes: checkinPendentesDaExecucao(pendentes, execucao.id),
    );
  }

  /// Envia a fila e soma ao [base] o que foi aceito. Série recusada saiu da
  /// fila: a execução volta à do servidor.
  Future<CheckinSessaoEstado> sincronizar(ExecucaoTreino? base) async {
    final r = await enviarFila();
    ExecucaoTreino? atual;
    if (base != null) {
      var t = base;
      for (final e in r.enviadas) {
        if (e.execucaoId == t.id) t = checkinComExercicio(t, e.exercicio);
      }
      atual = checkinAplicarPendentes(t, r.restantes);
    }
    final pendentes = checkinPendentesDaExecucao(r.restantes, atual?.id);
    if (r.rejeitadas > 0) {
      final id = atual?.id;
      if (id != null) atual = await recarregar(id) ?? atual;
    }
    return CheckinSessaoEstado(execucao: atual, pendentes: pendentes);
  }

  /// Execução do servidor com a fila por cima; `null` sem rede.
  Future<ExecucaoTreino?> recarregar(int execucaoId) async {
    try {
      final servidor = await repo.detalhe(execucaoId);
      return checkinAplicarPendentes(servidor, await fila.ler());
    } catch (_) {
      return null;
    }
  }

  /// Concluir é idempotente: retry depois de timeout volta sem evolução (ou o
  /// 400 "já foi concluído" do backend antigo) e segue como sucesso.
  Future<CheckinConclusao> concluir(int execucaoId) async {
    var concluida = await checkinConcluir(() => repo.concluir(execucaoId));
    if (concluida == null) {
      try {
        concluida = await repo.detalhe(execucaoId);
      } catch (_) {}
    }
    SessaoEvolucaoDto? evolucao;
    try {
      evolucao = await repo.evolucaoSessao(execucaoId);
    } catch (_) {}
    return CheckinConclusao(concluida: concluida, evolucao: evolucao);
  }

  /// Descarta no servidor e tira as séries dessa execução da fila.
  Future<void> descartar(int execucaoId) async {
    await repo.descartar(execucaoId);
    await fila.removerDaExecucao(execucaoId);
  }
}
