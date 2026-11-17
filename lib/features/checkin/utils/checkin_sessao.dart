import '../../../core/api/transient_error.dart';
import '../data/checkin_offline.dart';
import '../../../core/analytics/analytics_service.dart';
import '../data/checkin_repository.dart';
import '../data/checkin_series_pendentes.dart';
import 'checkin_execucao_estado.dart';
import 'checkin_serie_input.dart' show CheckinSerieRestante;
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

  final CheckinSessoesLocaisStore locais = const CheckinSessoesLocaisStore();

  /// Abre (ou retoma) a sessão do treino e aplica o que está na fila. Sem
  /// internet, abre do pacote da semana numa sessão local (só o aluno).
  Future<CheckinSessaoEstado> iniciar(int treinoId, {DateTime Function() agora = DateTime.now}) async {
    final ExecucaoTreino recebida;
    try {
      recebida = await repo.iniciar(treinoId);
    } catch (e) {
      final local = await _iniciarLocal(treinoId, e, agora());
      if (local == null) rethrow;
      final pendentes = await fila.ler();
      final execucao = checkinAplicarPendentes(local, pendentes);
      return CheckinSessaoEstado(execucao: execucao, pendentes: checkinPendentesDaExecucao(pendentes, execucao.id));
    }
    final pendentes = await fila.ler();
    final execucao = checkinAplicarPendentes(recebida, pendentes);
    return CheckinSessaoEstado(
      execucao: execucao,
      pendentes: checkinPendentesDaExecucao(pendentes, execucao.id),
    );
  }

  /// Envia a fila e soma o que foi aceito à execução [atualAgora] lida
  /// *depois* do envio: série marcada enquanto a fila subia não pode sumir.
  /// Série recusada saiu da fila: a execução volta à do servidor.
  Future<CheckinSessaoEstado> sincronizar(
    ExecucaoTreino? Function() atualAgora,
  ) async {
    final r = await enviarFila();
    final base = atualAgora();
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

  Future<ExecucaoTreino?> _iniciarLocal(int treinoId, Object erro, DateTime agora) async {
    if (!isTransientApiError(erro) || repo.canal is! CanalDoAluno) return null;
    final pacote = await CheckinPacoteStore.ler();
    final previa = pacote?.treino(treinoId);
    if (pacote == null || previa == null || pacote.bloqueado || previa.exercicios.isEmpty) return null;
    final sessao = await locais.abertaDo(treinoId) ??
        SessaoLocal(
          chave: -agora.millisecondsSinceEpoch ~/ 1000,
          clienteId: novoClienteId(),
          treinoId: treinoId,
          treinoNome: previa.treinoNome,
          iniciadoEm: agora,
        );
    await locais.salvar(sessao);
    return execucaoLocal(previa, sessao);
  }

  /// "Já fiz": sem internet vira uma sessão local concluída sem séries.
  Future<void> jaFiz(int treinoId, {DateTime Function() agora = DateTime.now}) async {
    try {
      await repo.confirmarPlano(treinoId);
    } catch (e) {
      if (!isTransientApiError(e) || repo.canal is! CanalDoAluno) rethrow;
      final pacote = await CheckinPacoteStore.ler();
      final t = agora();
      await locais.salvar(SessaoLocal(
        chave: -t.millisecondsSinceEpoch ~/ 1000,
        clienteId: novoClienteId(),
        treinoId: treinoId,
        treinoNome: pacote?.treino(treinoId)?.treinoNome ?? 'Treino',
        iniciadoEm: t,
      ).concluir(t, jaFiz: true));
    }
  }

  /// Concluir é idempotente: retry depois de timeout volta sem evolução (ou o
  /// 400 "já foi concluído" do backend antigo) e segue como sucesso. Sem
  /// internet, guarda a hora de agora e manda quando a rede voltar.
  Future<CheckinConclusao> concluir(int execucaoId, {DateTime Function() agora = DateTime.now}) async {
    if (execucaoId < 0) {
      final local = await locais.daChave(execucaoId);
      if (local != null) await locais.salvar(local.concluir(agora()));
      checkinTreinoConcluido(modo: 'sem_internet');
      try {
        await sincronizarSessoesLocais(repo: repo, store: locais, fila: fila);
      } catch (_) {}
      return const CheckinConclusao(concluida: null);
    }
    final ExecucaoTreino? concluidaAgora;
    try {
      concluidaAgora = await checkinConcluir(() => repo.concluir(execucaoId));
    } catch (e) {
      if (!isTransientApiError(e)) rethrow;
      await locais.concluirDepois(execucaoId, agora());
      checkinTreinoConcluido(modo: 'sem_internet');
      return const CheckinConclusao(concluida: null);
    }
    var concluida = concluidaAgora;
    if (concluida == null) {
      try {
        concluida = await repo.detalhe(execucaoId);
      } catch (_) {}
    }
    if (concluida != null) checkinTreinoConcluido(modo: 'registrado');
    SessaoEvolucaoDto? evolucao;
    try {
      evolucao = await repo.evolucaoSessao(execucaoId);
    } catch (_) {}
    return CheckinConclusao(concluida: concluida, evolucao: evolucao);
  }

  /// Registra uma série: online grava; falha transitória guarda na fila e
  /// conta como feita; recusa devolve o erro.
  Future<CheckinRegistro> registrarSerie(
    CheckinSeriePendente serie, {
    required CheckinSessaoAtiva sessaoAtiva,
  }) =>
      checkinRegistrarSerie(
        serie: serie,
        store: fila,
        enviar: checkinEnvioPelo(repo),
        sessaoAtiva: sessaoAtiva,
      );

  /// Volta uma série do exercício (mexe em série gravada: chame com a fila
  /// vazia).
  Future<ExecucaoExercicio> desfazerSerie(int execucaoId, ExecucaoExercicio ee) =>
      repo.marcarExercicio(
        execucaoId,
        ee.treinoExercicioId,
        ee.seriesFeitas - 1,
        feedback: ee.feedback,
        rpe: ee.rpe,
        dor: ee.dor,
      );

  /// Grava as séries que faltam do exercício como estão na tela.
  Future<ExecucaoExercicio> confirmarRestante(
    int execucaoId,
    ExecucaoExercicio ee,
    List<CheckinSerieRestante> series,
  ) =>
      repo.confirmarRestante(execucaoId, ee.treinoExercicioId, series: series);

  /// Descarta no servidor e tira as séries dessa execução da fila. Sessão
  /// local só some do aparelho.
  Future<void> descartar(int execucaoId) async {
    if (execucaoId < 0) {
      await locais.remover(execucaoId);
    } else {
      await repo.descartar(execucaoId);
    }
    await fila.removerDaExecucao(execucaoId);
  }
}

/// Treino terminado vai para o Amplitude ([ProductEvents.treinoConcluido]).
void checkinTreinoConcluido({required String modo}) {
  AnalyticsService.instance.track(
    ProductEvents.treinoConcluido,
    props: {'modo': modo},
  );
}
