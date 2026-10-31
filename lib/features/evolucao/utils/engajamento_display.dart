import '../data/evolucao_repository.dart';
import '../../../l10n/pt.dart';

const engajamentoPeriodos = [30, 60, 90];

String engajamentoPeriodoLabel(int dias) => '$dias dias';

String engajamentoTipoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'TREINO':
    case 'TREINO_INICIADO':
      return ptS.aluno360FerramentasGrupoTreino;
    case 'CHECKIN_CONCLUIDO':
      return ptS.engajamentoCheckIn;
    case 'MEDIDA':
      return ptS.engajamentoMedida;
    case 'MENSAGEM':
      return ptS.copilotoMensagemCampo;
    case 'EM_ANDAMENTO':
      return ptS.historicoDetalheEmAndamento;
    case '':
      return ptS.engajamentoEvento;
    default:
      return tipo!.trim();
  }
}

String engajamentoFxIcon(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'TREINO':
    case 'TREINO_INICIADO':
    case 'CHECKIN_CONCLUIDO':
      return 'dumbbell';
    case 'MEDIDA':
      return 'trend';
    case 'MENSAGEM':
      return 'chat';
    default:
      return 'calendar';
  }
}

String engajamentoEventoLabel(String? descricao, String? tipo) {
  final text = descricao?.trim();
  if (text != null && text.isNotEmpty) {
    return text
        .replaceAll(' - ', ' · ')
        .replaceAll('EM_ANDAMENTO', ptS.engajamentoEmAndamento)
        .replaceAll('CONCLUIDO', 'concluído')
        .replaceAll('CANCELADO', 'cancelado')
        .replaceAll('_', ' ');
  }
  return engajamentoTipoLabel(tipo);
}

/// Tipo do evento como apoio; nulo quando o título já é o próprio tipo.
String? engajamentoEventoSubtitle({
  required String? tipo,
  required String titulo,
}) {
  if ((tipo ?? '').trim().toUpperCase() == 'MENSAGEM') return null;
  final label = engajamentoTipoLabel(tipo);
  return label.toLowerCase() == titulo.trim().toLowerCase() ? null : label;
}

String engajamentoHoraLabel(String dataHora) {
  final dt = DateTime.tryParse(dataHora)?.toLocal();
  if (dt == null) return '—';
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String engajamentoDiaLabel(String dataHora, {DateTime? now}) {
  final dt = DateTime.tryParse(dataHora)?.toLocal();
  if (dt == null) return ptS.engajamentoSemData;
  final ref = now ?? DateTime.now();
  final hoje = DateTime(ref.year, ref.month, ref.day);
  final dia = DateTime(dt.year, dt.month, dt.day);
  final diff = hoje.difference(dia).inDays;
  if (diff == 0) return ptS.dockHoje;
  if (diff == 1) return ptS.treinosDiaOntem;
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$d/$m';
}

typedef EngajamentoLinha = ({String? dia, EventoEngajamento? evento});

/// Achata eventos (já ordenados do mais recente) em cabeçalho de dia + itens.
List<EngajamentoLinha> engajamentoLinhasPorDia(
  List<EventoEngajamento> eventos, {
  DateTime? now,
}) {
  final linhas = <EngajamentoLinha>[];
  String? atual;
  for (final evento in eventos) {
    final dia = engajamentoDiaLabel(evento.dataHora, now: now);
    if (dia != atual) {
      linhas.add((dia: dia, evento: null));
      atual = dia;
    }
    linhas.add((dia: null, evento: evento));
  }
  return linhas;
}

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

/// Parcial, cancelado e em andamento ficam fora, como na aderência.
int engajamentoTreinosCount(Iterable<EventoEngajamento> eventos) =>
    eventos.where(_treinoFeito).length;

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
  final semana = feitos.where((d) => !d.isBefore(corte)).length;
  final vezes = switch (semana) {
    0 => ptS.engajamentoNaoTreinouNosUltimos7,
    1 => ptS.engajamentoTreinou1VezNosUltimos,
    _ => ptS.engajamentoTreinouVezesNosUltimos7(semana),
  };
  return ptS.engajamentoUltimoTreino(vezes, _haDias(feitos.last, ref));
}

/// Treinos feitos nos últimos 7 dias, com hoje.
int engajamentoTreinosSemana(
  Iterable<EventoEngajamento> eventos, {
  DateTime? now,
}) {
  final corte = _dia(now ?? DateTime.now()).subtract(const Duration(days: 6));
  return eventos
      .where(_treinoFeito)
      .map(_quando)
      .nonNulls
      .where((d) => !d.isBefore(corte))
      .length;
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

enum EngajamentoFiltro { tudo, treinos, medidas, mensagens }

String engajamentoFiltroLabel(EngajamentoFiltro filtro) => switch (filtro) {
  EngajamentoFiltro.tudo => ptS.engajamentoTudo,
  EngajamentoFiltro.treinos => ptS.dockTreinos,
  EngajamentoFiltro.medidas => ptS.engajamentoMedidas,
  EngajamentoFiltro.mensagens => ptS.engajamentoMensagens,
};

int engajamentoCanceladosCount(Iterable<EventoEngajamento> eventos) =>
    eventos
        .where(
          (e) =>
              engajamentoEhTreino(e) &&
              engajamentoTreinoEstado(e) == EngajamentoTreinoEstado.cancelado,
        )
        .length;

/// Eventos da lista: mensagens do dia viram uma linha e cancelados só a pedido.
List<EventoEngajamento> engajamentoAtividade(
  List<EventoEngajamento> eventos, {
  required EngajamentoFiltro filtro,
  bool mostrarCancelados = false,
}) {
  final porDia = <String, int>{};
  for (final e in eventos.where(engajamentoEhMensagem)) {
    final chave = e.dataHora.split('T').first;
    porDia[chave] = (porDia[chave] ?? 0) + 1;
  }
  final vistos = <String>{};
  final saida = <EventoEngajamento>[];
  for (final e in eventos) {
    final tipo = e.tipo.trim().toUpperCase();
    final treino = engajamentoEhTreino(e);
    final passa = switch (filtro) {
      EngajamentoFiltro.tudo => true,
      EngajamentoFiltro.treinos => treino,
      EngajamentoFiltro.medidas => tipo == 'MEDIDA',
      EngajamentoFiltro.mensagens => engajamentoEhMensagem(e),
    };
    if (!passa) continue;
    if (treino &&
        !mostrarCancelados &&
        engajamentoTreinoEstado(e) == EngajamentoTreinoEstado.cancelado) {
      continue;
    }
    if (!engajamentoEhMensagem(e)) {
      saida.add(e);
      continue;
    }
    final chave = e.dataHora.split('T').first;
    if (!vistos.add(chave)) continue;
    final total = porDia[chave]!;
    saida.add(
      total == 1
          ? e
          : EventoEngajamento(
            tipo: e.tipo,
            descricao: '$total mensagens',
            dataHora: e.dataHora,
          ),
    );
  }
  return saida;
}

String? engajamentoEventoRota(String? tipo, int alunoId) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'MENSAGEM':
      return '/alunos/$alunoId/chat';
    case 'MEDIDA':
      return '/alunos/$alunoId/evolucao';
    case 'TREINO':
    case 'TREINO_INICIADO':
    case 'CHECKIN_CONCLUIDO':
      return '/alunos/$alunoId/rotina';
    default:
      return null;
  }
}
