import '../../treinos/models/rotina_fila.dart';
import '../models/checkin_execucao_models.dart';
import 'treino_ficha_status.dart';

enum RotinaMomento { continuar, pronto, agora, descansoDia, preparacao }

class RotinaDecisao {
  const RotinaDecisao({
    required this.momento,
    required this.foco,
    this.depois,
    this.proximoEhDescanso = false,
    this.ordem = 0,
    this.ordemTotal = 0,
    this.depoisNome,
    this.exerciciosFeitos,
  });

  final RotinaMomento momento;
  final ExecucaoTreino foco;
  final ExecucaoTreino? depois;
  final bool proximoEhDescanso;
  final int ordem;
  final int ordemTotal;
  final String? depoisNome;
  final int? exerciciosFeitos;
}

/// Uma saída para Home e aba Treinos. Fila vazia devolve null e o caminho antigo fica.
RotinaDecisao? decisaoDaRotina({
  required List<RotinaItem> itens,
  required Set<int> diasAviso,
  required List<ExecucaoTreino> treinos,
  required List<ExecucaoTreino> historico,
  required DateTime agora,
}) {
  if (itens.isEmpty) return null;
  final porId = <int, ExecucaoTreino>{
    for (final treino in treinos) treino.treinoId: treino,
  };

  for (final treino in treinos) {
    if (normalizeTreinoStatus(treino.status) == treinoStatusEmAndamento) {
      return _agora(
        momento: RotinaMomento.continuar,
        itens: itens,
        porId: porId,
        foco: treino,
        exerciciosFeitos: _feitos(historico, treino.treinoId),
      );
    }
  }

  final feito = treinoConcluidoHoje(historico, now: agora);
  if (feito != null) {
    final idx = _indice(itens, feito.treinoId);
    final imediato = idx == null ? null : _passo(itens, idx, 1);
    final depois = _proximoTreino(itens, idx ?? -1, porId);
    return RotinaDecisao(
      momento: RotinaMomento.pronto,
      foco: feito,
      depois: depois,
      proximoEhDescanso: imediato?.descanso ?? false,
      depoisNome: depois?.treinoNome,
    );
  }

  final proximo = _proximoTreino(itens, _indiceDoUltimo(itens, historico), porId);
  if (diasAviso.contains(agora.weekday)) {
    if (proximo != null) {
      return RotinaDecisao(momento: RotinaMomento.descansoDia, foco: proximo);
    }
  }

  if (proximo != null) {
    return _agora(
      momento: RotinaMomento.agora,
      itens: itens,
      porId: porId,
      foco: proximo,
    );
  }

  for (final treino in treinos) {
    if (isTreinoAguardandoLiberacao(treino)) {
      return RotinaDecisao(momento: RotinaMomento.preparacao, foco: treino);
    }
  }
  return null;
}

/// O que o personal lê no topo, a partir dos campos que a API manda sem o histórico.
RotinaDecisao? decisaoParaPersonal(RotinaFila rotina, DateTime agora) {
  if (rotina.itens.isEmpty) return null;
  final treinos = <ExecucaoTreino>[
    for (final item in rotina.itens)
      if (!item.descanso && item.treinoId != null)
        ExecucaoTreino(
          treinoId: item.treinoId!,
          treinoNome: item.nome?.trim().isNotEmpty == true ? item.nome!.trim() : 'Treino',
          status: item.treinoId == rotina.sessaoAbertaTreinoId
              ? treinoStatusEmAndamento
              : treinoStatusDisponivel,
          exercicios: const [],
          exerciciosCount: 1,
        ),
  ];
  final historico = <ExecucaoTreino>[];
  final ultimo = rotina.ultimoTreinoId;
  if (ultimo != null) {
    final quando = rotina.concluiuHoje ? agora : agora.subtract(const Duration(days: 1));
    final nome = treinos
        .where((treino) => treino.treinoId == ultimo)
        .map((treino) => treino.treinoNome)
        .firstOrNull;
    historico.add(
      ExecucaoTreino(
        treinoId: ultimo,
        treinoNome: nome ?? 'Treino',
        status: treinoStatusConcluido,
        iniciadoEm: quando.subtract(const Duration(hours: 1)).toIso8601String(),
        concluidoEm: quando.toIso8601String(),
        exercicios: const [],
      ),
    );
  }
  return decisaoDaRotina(
    itens: rotina.itens,
    diasAviso: rotina.diasAviso,
    treinos: treinos,
    historico: historico,
    agora: agora,
  );
}

RotinaDecisao _agora({
  required RotinaMomento momento,
  required List<RotinaItem> itens,
  required Map<int, ExecucaoTreino> porId,
  required ExecucaoTreino foco,
  int? exerciciosFeitos,
}) {
  final prontos = <ExecucaoTreino>[
    for (final item in itens)
      if (!item.descanso)
        if (porId[item.treinoId] case final treino?)
          if (isTreinoDisponivelParaIniciar(treino) ||
              treino.treinoId == foco.treinoId)
            treino,
  ];
  final idx = prontos.indexWhere((treino) => treino.treinoId == foco.treinoId);
  final depois = prontos.length > 1 ? prontos[(idx + 1) % prontos.length] : null;
  return RotinaDecisao(
    momento: momento,
    foco: foco,
    ordem: idx < 0 ? 1 : idx + 1,
    ordemTotal: prontos.length,
    depoisNome: depois?.treinoNome,
    exerciciosFeitos: exerciciosFeitos,
  );
}

int _indiceDoUltimo(List<RotinaItem> itens, List<ExecucaoTreino> historico) {
  (int, DateTime)? ultimo;
  for (final item in historico) {
    if (normalizeTreinoStatus(item.status) != treinoStatusConcluido) continue;
    final raw = item.concluidoEm ?? item.iniciadoEm;
    final quando = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (quando == null) continue;
    if (ultimo == null || quando.isAfter(ultimo.$2)) ultimo = (item.treinoId, quando);
  }
  if (ultimo == null) return -1;
  return _indice(itens, ultimo.$1) ?? -1;
}

ExecucaoTreino? _proximoTreino(
  List<RotinaItem> itens,
  int depoisDe,
  Map<int, ExecucaoTreino> porId,
) {
  if (itens.isEmpty) return null;
  for (var passo = 1; passo <= itens.length; passo++) {
    final item = _passo(itens, depoisDe, passo);
    if (item == null || item.descanso || item.treinoId == null) continue;
    final treino = porId[item.treinoId];
    if (treino != null && isTreinoDisponivelParaIniciar(treino)) return treino;
  }
  return null;
}

RotinaItem? _passo(List<RotinaItem> itens, int depoisDe, int passo) {
  if (itens.isEmpty) return null;
  return itens[(depoisDe + passo) % itens.length];
}

int? _indice(List<RotinaItem> itens, int treinoId) {
  for (var i = 0; i < itens.length; i++) {
    if (!itens[i].descanso && itens[i].treinoId == treinoId) return i;
  }
  return null;
}

int? _feitos(List<ExecucaoTreino> historico, int treinoId) {
  for (final item in historico) {
    if (item.treinoId == treinoId &&
        normalizeTreinoStatus(item.status) == treinoStatusEmAndamento) {
      return item.exerciciosConcluidos;
    }
  }
  return null;
}
