import '../data/checkin_repository.dart';
import 'treino_ficha_status.dart';

enum TreinosDestaqueTipo { emAndamento, concluidoHoje, proximo, emPreparacao }

/// Card principal da aba Treinos. [treino] é a ficha; em [concluidoHoje] é a
/// execução do histórico (a ficha pode ter saído do plano).
class TreinosDestaque {
  const TreinosDestaque({
    required this.tipo,
    required this.treino,
    this.exerciciosFeitos,
    this.duracao,
  });

  final TreinosDestaqueTipo tipo;
  final ExecucaoTreino treino;

  /// Em andamento: exercícios concluídos na sessão aberta; null sem o dado.
  final int? exerciciosFeitos;

  /// Concluído hoje: duração real ([treinoDuracaoReal]).
  final Duration? duracao;
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
}) {
  final destaque = _destaque(treinos, historico, now);
  final depois =
      destaque?.tipo == TreinosDestaqueTipo.concluidoHoje
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
    if (normalizeTreinoStatus(h.status) != treinoStatusConcluido) continue;
    if (excluirExecucaoId != null && h.id == excluirExecucaoId) continue;
    final quando = _parseLocal(h.concluidoEm) ?? _parseLocal(h.iniciadoEm);
    if (quando == null) continue;
    concluidos.add(
      TreinoRecente(
        execucao: h,
        quando: quando,
        duracao: treinoDuracaoReal(h.iniciadoEm, h.concluidoEm),
      ),
    );
  }
  concluidos.sort((a, b) => b.quando.compareTo(a.quando));
  return concluidos.take(treinosHubUltimosMax).toList();
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
