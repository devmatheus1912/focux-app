import '../data/evolucao_repository.dart';
import '../../../l10n/pt.dart';

enum EngajamentoTreinoEstado { feito, parcial, cancelado, aberto }

bool engajamentoEhTreino(EventoEngajamento e) {
  switch (e.tipo.trim().toUpperCase()) {
    case 'TREINO':
    case 'TREINO_INICIADO':
    case 'CHECKIN_CONCLUIDO':
      return true;
    default:
      return false;
  }
}

bool engajamentoEhMensagem(EventoEngajamento e) =>
    e.tipo.trim().toUpperCase() == 'MENSAGEM';

/// `status` do backend; build contra backend antigo lê o texto.
EngajamentoTreinoEstado engajamentoTreinoEstado(EventoEngajamento e) {
  final bruto = (e.status ?? e.descricao).toUpperCase();
  if (bruto.contains('CANCELADO')) return EngajamentoTreinoEstado.cancelado;
  if (bruto.contains('PARCIAL')) return EngajamentoTreinoEstado.parcial;
  if (bruto.contains('EM_ANDAMENTO') || bruto.contains('EM ANDAMENTO')) {
    return EngajamentoTreinoEstado.aberto;
  }
  return EngajamentoTreinoEstado.feito;
}

bool _treinoFeito(EventoEngajamento e) =>
    engajamentoEhTreino(e) &&
    engajamentoTreinoEstado(e) == EngajamentoTreinoEstado.feito;

DateTime? _quando(EventoEngajamento e) =>
    DateTime.tryParse(e.dataHora)?.toLocal();

DateTime _dia(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _haDias(DateTime quando, DateTime now) {
  final dias = _dia(now).difference(_dia(quando)).inDays;
  if (dias <= 0) return 'hoje';
  if (dias == 1) return 'ontem';
  return ptS.engajamentoHaDias(dias);
}

/// Resposta curta para "esse aluno está firme?".
String engajamentoFrase(List<EventoEngajamento> eventos, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final feitos =
      eventos.where(_treinoFeito).map(_quando).nonNulls.toList()..sort();
  if (feitos.isEmpty) return ptS.engajamentoNenhumTreinoFeitoNestePeriodo;
  final corte = _dia(ref).subtract(const Duration(days: 6));
  final semana = feitos.where((d) => !d.isBefore(corte)).map(_dia).toSet().length;
  final vezes = switch (semana) {
    0 => ptS.engajamentoNaoTreinouNosUltimos7,
    1 => ptS.engajamentoTreinou1VezNosUltimos,
    _ => ptS.engajamentoTreinouVezesNosUltimos7(semana),
  };
  return ptS.engajamentoUltimoTreino(vezes, _haDias(feitos.last, ref));
}

/// Dias do período mais recente, do mais antigo para hoje.
List<({DateTime dia, EngajamentoTreinoEstado? estado})> engajamentoCalendario(
  Iterable<EventoEngajamento> eventos, {
  DateTime? now,
  int dias = 35,
}) {
  final hoje = _dia(now ?? DateTime.now());
  final porDia = <DateTime, EngajamentoTreinoEstado>{};
  for (final e in eventos.where(engajamentoEhTreino)) {
    final quando = _quando(e);
    final estado = engajamentoTreinoEstado(e);
    if (quando == null || estado == EngajamentoTreinoEstado.aberto) continue;
    // Vale o melhor do dia: feito, depois parcial, depois cancelado.
    final atual = porDia[_dia(quando)];
    if (atual == null || estado.index < atual.index) {
      porDia[_dia(quando)] = estado;
    }
  }
  return [
    for (var i = dias - 1; i >= 0; i--)
      (
        dia: DateTime(hoje.year, hoje.month, hoje.day - i),
        estado: porDia[DateTime(hoje.year, hoje.month, hoje.day - i)],
      ),
  ];
}

enum EngajamentoDiaEstado {
  treinou,
  parcial,
  cancelou,
  faltou,
  descanso,
  semRegistro,
  futuro,
}

class EngajamentoDia {
  const EngajamentoDia({
    required this.dia,
    required this.estado,
    required this.hoje,
  });

  final DateTime dia;
  final EngajamentoDiaEstado estado;
  final bool hoje;
}

class EngajamentoSemana {
  const EngajamentoSemana({required this.inicio, required this.dias});

  final DateTime inicio;
  final List<EngajamentoDia> dias;
}

/// Período do resumo e do quadro.
enum EngajamentoPeriodo { cincoSemanas, trintaDias, mesPassado }

String engajamentoPeriodoRotulo(EngajamentoPeriodo p) => switch (p) {
  EngajamentoPeriodo.cincoSemanas => ptS.engajamentoUltimas5Semanas,
  EngajamentoPeriodo.trintaDias => ptS.engajamentoPeriodo30Dias,
  EngajamentoPeriodo.mesPassado => ptS.engajamentoPeriodoMesPassado,
};

/// O que pedir ao servidor: últimos N dias ou o mês passado inteiro.
({int dias, DateTime? inicio, DateTime? fim}) engajamentoPeriodoConsulta(
  EngajamentoPeriodo p, {
  DateTime? now,
}) {
  final hoje = _dia(now ?? DateTime.now());
  return switch (p) {
    EngajamentoPeriodo.cincoSemanas => (dias: 35, inicio: null, fim: null),
    EngajamentoPeriodo.trintaDias => (dias: 30, inicio: null, fim: null),
    EngajamentoPeriodo.mesPassado => (
      dias: 31,
      inicio: DateTime(hoje.year, hoje.month - 1, 1),
      fim: DateTime(hoje.year, hoje.month, 0),
    ),
  };
}

/// Semanas do quadro: no padrão, desde a semana do início do acompanhamento
/// (sem semanas vazias de antes dele), até 5; no mês passado, as do mês.
({int semanas, DateTime? ate}) engajamentoQuadroDoPeriodo(
  EngajamentoPeriodo p, {
  required int diaDaFicha,
  DateTime? now,
}) {
  final hoje = _dia(now ?? DateTime.now());
  DateTime segundaDe(DateTime d) => DateTime(d.year, d.month, d.day - d.weekday + 1);
  int semanasEntre(DateTime de, DateTime ate) =>
      segundaDe(ate).difference(segundaDe(de)).inDays ~/ 7 + 1;
  switch (p) {
    case EngajamentoPeriodo.mesPassado:
      final consulta = engajamentoPeriodoConsulta(p, now: hoje);
      return (
        semanas: semanasEntre(consulta.inicio!, consulta.fim!),
        ate: consulta.fim,
      );
    case EngajamentoPeriodo.cincoSemanas:
    case EngajamentoPeriodo.trintaDias:
      if (diaDaFicha <= 0) return (semanas: 5, ate: null);
      final inicio = DateTime(hoje.year, hoje.month, hoje.day - diaDaFicha + 1);
      return (semanas: semanasEntre(inicio, hoje).clamp(1, 5), ate: null);
  }
}

/// "12 pontos acima do período anterior"; nulo sem os dois períodos medidos.
({int diferenca, String texto})? engajamentoTendenciaPeriodo(int? diferenca) {
  if (diferenca == null) return null;
  final texto =
      diferenca > 0
          ? ptS.engajamentoTendenciaSubiu(diferenca)
          : diferenca < 0
          ? ptS.engajamentoTendenciaCaiu(-diferenca)
          : ptS.engajamentoTendenciaIgual;
  // O cartão desenha a seta pela diferença.
  return (diferenca: diferenca, texto: texto);
}

/// Nenhum treino ainda e nenhum dia previsto já perdido: a semana só começou.
bool engajamentoSemanaComecou(EngajamentoSemana semana) =>
    semana.dias.every(
      (d) =>
          d.estado != EngajamentoDiaEstado.treinou &&
          d.estado != EngajamentoDiaEstado.faltou &&
          d.estado != EngajamentoDiaEstado.parcial,
    );

/// Semanas de segunda a domingo, a de [ate] (padrão: hoje) por último. Sem
/// [diasDescanso] o app não sabe o que era previsto: dia sem treino fica
/// "sem registro", nunca falta.
List<EngajamentoSemana> engajamentoSemanas(
  Iterable<EventoEngajamento> eventos, {
  required List<int> diasDescanso,
  required int diaDaFicha,
  DateTime? now,
  int semanas = 5,
  DateTime? ate,
}) {
  final hoje = _dia(now ?? DateTime.now());
  final ultimo = _dia(ate ?? hoje);
  // Antes do início do acompanhamento não havia treino previsto: nada é falta.
  final inicio = DateTime(hoje.year, hoje.month, hoje.day - diaDaFicha + 1);
  final segunda = DateTime(
    ultimo.year,
    ultimo.month,
    ultimo.day - ultimo.weekday + 1,
  );
  final porDia = {
    for (final d in engajamentoCalendario(
      eventos,
      now: ultimo,
      dias: semanas * 7 + 7,
    ))
      d.dia: d.estado,
  };
  EngajamentoDiaEstado estado(DateTime dia) {
    if (dia.isAfter(hoje)) return EngajamentoDiaEstado.futuro;
    switch (porDia[dia]) {
      case EngajamentoTreinoEstado.feito:
        return EngajamentoDiaEstado.treinou;
      case EngajamentoTreinoEstado.parcial:
        return EngajamentoDiaEstado.parcial;
      case EngajamentoTreinoEstado.cancelado:
        return EngajamentoDiaEstado.cancelou;
      default:
    }
    if (diasDescanso.contains(dia.weekday)) return EngajamentoDiaEstado.descanso;
    if (diasDescanso.isEmpty || diaDaFicha <= 0 || dia.isBefore(inicio)) {
      return EngajamentoDiaEstado.semRegistro;
    }
    // Hoje ainda pode treinar.
    return dia == hoje
        ? EngajamentoDiaEstado.semRegistro
        : EngajamentoDiaEstado.faltou;
  }

  return [
    for (var s = semanas - 1; s >= 0; s--)
      EngajamentoSemana(
        inicio: DateTime(segunda.year, segunda.month, segunda.day - s * 7),
        dias: [
          for (var d = 0; d < 7; d++)
            () {
              final dia = DateTime(
                segunda.year,
                segunda.month,
                segunda.day - s * 7 + d,
              );
              return EngajamentoDia(
                dia: dia,
                estado: estado(dia),
                hoje: dia == hoje,
              );
            }(),
        ],
      ),
  ];
}

/// Dias de treino feitos e dias esperados no quadro, sem contar o futuro.
({int feitos, int previstos}) engajamentoContagemQuadro(
  List<EngajamentoSemana> semanas,
) {
  var feitos = 0;
  var faltas = 0;
  for (final dia in semanas.expand((s) => s.dias)) {
    if (dia.estado == EngajamentoDiaEstado.treinou) feitos++;
    if (dia.estado == EngajamentoDiaEstado.faltou) faltas++;
  }
  return (feitos: feitos, previstos: feitos + faltas);
}

/// "2" dias com treino na semana de hoje.
int engajamentoDiasNaSemana(EngajamentoSemana semana) =>
    semana.dias.where((d) => d.estado == EngajamentoDiaEstado.treinou).length;

String engajamentoDataCurta(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

String engajamentoDiaCompleto(DateTime d) {
  const dias = [
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo',
  ];
  return '${dias[d.weekday - 1]}, ${engajamentoDataCurta(d)}';
}

String engajamentoUltimoTreino(int? diasSemTreino) => switch (diasSemTreino) {
  null => '—',
  0 => ptS.engajamentoHoje,
  1 => ptS.engajamentoOntem,
  final n => ptS.engajamentoHaNDias(n),
};

/// Quem falou por último. Nulo sem conversa na janela.
({String texto, bool semResposta})? engajamentoConversa(
  List<EventoEngajamento> eventos, {
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  EventoEngajamento? ultima;
  EventoEngajamento? ultimaDoAluno;
  for (final e in eventos.where(engajamentoEhMensagem)) {
    if (ultima == null || e.dataHora.compareTo(ultima.dataHora) > 0) ultima = e;
    if (_doAluno(e) &&
        (ultimaDoAluno == null ||
            e.dataHora.compareTo(ultimaDoAluno.dataHora) > 0)) {
      ultimaDoAluno = e;
    }
  }
  if (ultima == null) return null;
  final quandoAluno = ultimaDoAluno == null ? null : _quando(ultimaDoAluno);
  return (
    texto:
        quandoAluno == null
            ? ptS.engajamentoOAlunoAindaNaoRespondeu
            : ptS.engajamentoUltimaMensagemDoAluno(_haDias(quandoAluno, ref)),
    semResposta: _doAluno(ultima),
  );
}

bool _doAluno(EventoEngajamento e) =>
    e.remetente == null
        ? e.descricao.toLowerCase().startsWith('aluno')
        : e.remetente!.toUpperCase() == 'ALUNO';

