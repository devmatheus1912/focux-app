import '../../treinos/models/rotina_fila.dart';
import '../data/checkin_repository.dart';
import 'rotina_decisao.dart';
import 'treino_ficha_status.dart';

enum TreinosDestaqueTipo {
  emAndamento,
  concluidoHoje,
  proximo,
  descansoHoje,
  emPreparacao,
}

/// Card principal da aba Treinos. [treino] é a ficha; em [concluidoHoje] é a
/// execução do histórico (a ficha pode ter saído do plano).
class TreinosDestaque {
  const TreinosDestaque({
    required this.tipo,
    required this.treino,
    this.exerciciosFeitos,
    this.duracao,
    this.ordem = 0,
    this.ordemTotal = 0,
    this.depoisNome,
    this.proximoEhDescanso = false,
  });

  final TreinosDestaqueTipo tipo;
  final ExecucaoTreino treino;

  /// Em andamento: exercícios concluídos na sessão aberta; null sem o dado.
  final int? exerciciosFeitos;

  /// Concluído hoje: duração real ([treinoDuracaoReal]).
  final Duration? duracao;

  final int ordem;
  final int ordemTotal;
  final String? depoisNome;
  final bool proximoEhDescanso;
}

class TreinoRecente {
  const TreinoRecente({
    required this.execucao,
    required this.quando,
    this.duracao,
  });

  final ExecucaoTreino execucao;
  final DateTime quando;
  final Duration? duracao;

  int get exerciciosConcluidos => execucao.exerciciosConcluidos ?? 0;
}

class TreinosHubView {
  const TreinosHubView({
    required this.destaque,
    required this.depois,
    required this.plano,
    required this.ultimos,
    required this.validaAte,
  });

  final TreinosDestaque? destaque;

  /// Só com o treino de hoje concluído: o próximo do rodízio.
  final ExecucaoTreino? depois;

  /// Fichas na ordem do rodízio, sem as que estão no destaque ou em [depois].
  final List<ExecucaoTreino> plano;
  final List<TreinoRecente> ultimos;

  /// Meia-noite seguinte: "concluído hoje", "Hoje" e "Ontem" mudam de valor.
  final DateTime validaAte;
}

const treinosHubUltimosMax = 3;

String treinoPreviaPath(int treinoId) => '/checkin/treino/$treinoId';
const _duracaoMin = Duration(minutes: 5);
const _duracaoMax = Duration(hours: 8);

TreinosHubView buildTreinosHubView({
  required List<ExecucaoTreino> treinos,
  required List<ExecucaoTreino> historico,
  required DateTime now,
  RotinaFila? rotina,
}) {
  final decisao = rotina == null || rotina.itens.isEmpty
      ? null
      : decisaoDaRotina(
          itens: rotina.itens,
          diasAviso: rotina.diasAviso,
          treinos: treinos,
          historico: historico,
          agora: now,
        );
  final destaque = decisao == null
      ? _destaque(treinos, historico, now)
      : _destaqueDaDecisao(decisao, historico);
  final depois = decisao != null
      ? (decisao.momento == RotinaMomento.pronto ? decisao.depois : null)
      : destaque?.tipo == TreinosDestaqueTipo.concluidoHoje
          ? proximoTreinoParaHoje(treinos: treinos, historico: historico)
          : null;

  final noTopo = {
    if (destaque != null) destaque.treino.treinoId,
    if (depois != null) depois.treinoId,
  };
  final plano = [
    for (final t in treinos)
      if (!noTopo.contains(t.treinoId)) t,
  ];

  final destaqueExecucaoId =
      destaque?.tipo == TreinosDestaqueTipo.concluidoHoje
          ? destaque!.treino.id
          : null;

  return TreinosHubView(
    destaque: destaque,
    depois: depois,
    plano: List.unmodifiable(plano),
    ultimos: List.unmodifiable(
      _ultimos(historico, excluirExecucaoId: destaqueExecucaoId),
    ),
    validaAte: DateTime(now.year, now.month, now.day + 1),
  );
}

TreinosDestaque _destaqueDaDecisao(
  RotinaDecisao decisao,
  List<ExecucaoTreino> historico,
) {
  final foco = decisao.foco;
  return switch (decisao.momento) {
    RotinaMomento.continuar => TreinosDestaque(
      tipo: TreinosDestaqueTipo.emAndamento,
      treino: foco,
      exerciciosFeitos:
          decisao.exerciciosFeitos ??
          _sessaoAberta(historico, foco.treinoId)?.exerciciosConcluidos,
      ordem: decisao.ordem,
      ordemTotal: decisao.ordemTotal,
      depoisNome: decisao.depoisNome,
    ),
    RotinaMomento.pronto => TreinosDestaque(
      tipo: TreinosDestaqueTipo.concluidoHoje,
      treino: foco,
      duracao: treinoDuracaoReal(foco.iniciadoEm, foco.concluidoEm),
      proximoEhDescanso: decisao.proximoEhDescanso,
      depoisNome: decisao.depoisNome,
    ),
    RotinaMomento.agora => TreinosDestaque(
      tipo: TreinosDestaqueTipo.proximo,
      treino: foco,
      ordem: decisao.ordem,
      ordemTotal: decisao.ordemTotal,
      depoisNome: decisao.depoisNome,
    ),
    RotinaMomento.descansoDia => TreinosDestaque(
      tipo: TreinosDestaqueTipo.descansoHoje,
      treino: foco,
    ),
    RotinaMomento.preparacao => TreinosDestaque(
      tipo: TreinosDestaqueTipo.emPreparacao,
      treino: foco,
    ),
  };
}

TreinosDestaque? _destaque(
  List<ExecucaoTreino> treinos,
  List<ExecucaoTreino> historico,
  DateTime now,
) {
  final aberta = treinoSessaoEmAndamento(treinos);
  if (aberta != null) {
    return TreinosDestaque(
      tipo: TreinosDestaqueTipo.emAndamento,
      treino: aberta,
      exerciciosFeitos:
          _sessaoAberta(historico, aberta.treinoId)?.exerciciosConcluidos,
    );
  }

  final feito = treinoConcluidoHoje(historico, now: now);
  if (feito != null) {
    return TreinosDestaque(
      tipo: TreinosDestaqueTipo.concluidoHoje,
      treino: feito,
      duracao: treinoDuracaoReal(feito.iniciadoEm, feito.concluidoEm),
    );
  }

  final proximo = proximoTreinoParaHoje(treinos: treinos, historico: historico);
  if (proximo != null) {
    return TreinosDestaque(tipo: TreinosDestaqueTipo.proximo, treino: proximo);
  }

  for (final t in treinos) {
    if (isTreinoAguardandoLiberacao(t)) {
      return TreinosDestaque(tipo: TreinosDestaqueTipo.emPreparacao, treino: t);
    }
  }
  return null;
}

ExecucaoTreino? _sessaoAberta(List<ExecucaoTreino> historico, int treinoId) {
  for (final h in historico) {
    if (h.treinoId == treinoId &&
        normalizeTreinoStatus(h.status) == treinoStatusEmAndamento) {
      return h;
    }
  }
  return null;
}

List<TreinoRecente> _ultimos(
  List<ExecucaoTreino> historico, {
  int? excluirExecucaoId,
}) {
  final concluidos = <TreinoRecente>[];
  for (final h in historico) {
    if (excluirExecucaoId != null && h.id == excluirExecucaoId) continue;
    if (treinoRecenteDe(h) case final r?) concluidos.add(r);
  }
  concluidos.sort((a, b) => b.quando.compareTo(a.quando));
  return concluidos.take(treinosHubUltimosMax).toList();
}

/// Sessão concluída com data (conclusão, senão início); null para as demais.
TreinoRecente? treinoRecenteDe(ExecucaoTreino h) {
  if (normalizeTreinoStatus(h.status) != treinoStatusConcluido) return null;
  final quando = _parseLocal(h.concluidoEm) ?? _parseLocal(h.iniciadoEm);
  if (quando == null) return null;
  return TreinoRecente(
    execucao: h,
    quando: quando,
    duracao: treinoDuracaoReal(h.iniciadoEm, h.concluidoEm),
  );
}

/// `concluidoEm − iniciadoEm` quando plausível (5 min a 8 h). Fora disso é
/// registro sem sessão ("Já fiz") ou relógio esquecido: não mostra.
Duration? treinoDuracaoReal(String? iniciadoEm, String? concluidoEm) {
  final inicio = _parseLocal(iniciadoEm);
  final fim = _parseLocal(concluidoEm);
  if (inicio == null || fim == null) return null;
  final d = fim.difference(inicio);
  if (d < _duracaoMin || d > _duracaoMax) return null;
  return d;
}

DateTime? _parseLocal(String? raw) {
  final t = raw?.trim() ?? '';
  return t.isEmpty ? null : DateTime.tryParse(t)?.toLocal();
}
