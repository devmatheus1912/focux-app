import '../../../l10n/pt.dart';

final broadcastPublicos = ['TODOS', 'ONLINE', 'PRESENCIAL', 'HIBRIDO'];

String broadcastPublicoLabel(String? raw) =>
    switch ((raw ?? 'TODOS').trim().toUpperCase()) {
      'ONLINE' => ptS.broadcastOnline,
      'PRESENCIAL' => ptS.broadcastPresencial,
      'HIBRIDO' => ptS.broadcastHibrido,
      _ => ptS.retencaoFiltroTodos,
    };

String broadcastPublicoFxIcon(String raw) => switch (raw.trim().toUpperCase()) {
  'ONLINE' => 'message-circle',
  'PRESENCIAL' => 'home',
  'HIBRIDO' => 'users',
  _ => 'users',
};

/// Rótulo do público com o alcance, quando já chegou.
String broadcastPublicoChip(String publico, int? total) {
  final label = broadcastPublicoLabel(publico);
  return total == null ? label : '$label $total';
}

/// "Todos" inclui quem ainda está sem tipo de consultoria.
String? broadcastSemTipoAviso(Map<String, int> totais) {
  final todos = totais['TODOS'];
  if (todos == null) return null;
  final comTipo = totais.entries
      .where((e) => e.key != 'TODOS')
      .fold<int>(0, (soma, e) => soma + e.value);
  final semTipo = todos - comTipo;
  if (semTipo <= 0) return null;
  return semTipo == 1
      ? ptS.broadcast1AlunoEstaSemTipo
      : ptS.broadcastAlunosEstaoSemTipoDe(semTipo);
}

final broadcastAtalhos = <({String nome, String titulo, String mensagem})>[
  (
    nome: ptS.broadcastLembreteDeTreino,
    titulo: ptS.broadcastLembreteDeTreino,
    mensagem: ptS.broadcastSeuTreinoDeHojeJa,
  ),
  (
    nome: ptS.broadcastFeriado,
    titulo: ptS.broadcastAtendimentoNoFeriado,
    mensagem: ptS.broadcastNoFeriadoNaoTereiAtendimento,
  ),
  (
    nome: ptS.broadcastMudancaDeHorario,
    titulo: ptS.broadcastMudancaDeHorario,
    mensagem: ptS.broadcastMeusHorariosMudaramConfiraA,
  ),
];

String? broadcastTipoApi(String publico) =>
    publico == 'TODOS' ? null : publico;

String broadcastRequiredTitulo() => ptS.broadcastInformeOTitulo;

String broadcastRequiredMensagem() => ptS.broadcastInformeAMensagem;

String broadcastSendSuccess(int count, {int? comPush}) {
  if (count <= 0) return ptS.broadcastNenhumAlunoNoPublicoEscolhido;
  final base = count == 1 ? ptS.broadcastEnviadoPara1Aluno : ptS.broadcastEnviadoParaAlunos(count);
  if (comPush == null) return '$base.';
  if (comPush >= count) return ptS.broadcastComNotificacaoNoCelular(base);
  if (comPush <= 0) {
    return ptS.broadcastNenhumTemNotificacaoAtivaEles(base);
  }
  return ptS.broadcastOsDemaisVeemAoAbrir(base, broadcastComPushLabel(comPush));
}

String broadcastComPushLabel(int comPush) =>
    comPush == 1 ? ptS.broadcast1ComNotificacao : ptS.broadcastComNotificacao(comPush);

String broadcastAlunosValue(int count, {int? comPush}) {
  final base = count == 1 ? ptS.broadcast1Aluno : '$count alunos';
  if (comPush == null) return base;
  return '$base · ${broadcastComPushLabel(comPush)}';
}

String broadcastAlunosLabel(int total) =>
    total == 1 ? ptS.broadcast1Aluno : '$total alunos';

String broadcastConfirmTitle(String publico, {int? total}) {
  if (total != null) return ptS.broadcastEnviarPara(broadcastAlunosLabel(total));
  if (publico == 'TODOS') return 'Enviar para todos os alunos?';
  return ptS.broadcastEnviarPara(broadcastPublicoLabel(publico).toLowerCase());
}

String broadcastConfirmMessage({int? total, int? comPush}) {
  if (total == null || comPush == null) {
    return ptS.broadcastOAvisoChegaDeUma;
  }
  if (comPush >= total) return ptS.broadcastTodosRecebemNoCelular;
  if (comPush <= 0) return ptS.broadcastElesVeemAoAbrirO;
  return ptS.broadcastRecebemNoCelularOsOutros(comPush);
}

String broadcastConfirmLabel() => ptS.npsPromptEnviar;

String broadcastEnviosCaption(int count) {
  if (count <= 0) return ptS.winbackVazioTitulo;
  if (count == 1) return ptS.broadcast1Envio;
  return '$count envios';
}

String broadcastHistoricoHeader() => ptS.anamneseAlunoHistorico;

String broadcastEmptyTitle() => ptS.broadcastNenhumAvisoEnviado;

String broadcastEmptySubtitle() =>
    ptS.broadcastEscrevaOPrimeiroAvisoAcima;

String broadcastFormatDate(DateTime dt) {
  final dia = dt.day.toString().padLeft(2, '0');
  final mes = dt.month.toString().padLeft(2, '0');
  final hora = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$dia/$mes · $hora:$min';
}

String broadcastTileSubtitle(String mensagem, DateTime enviadoEm) {
  final compact = mensagem.trim().replaceAll(RegExp(r'\s+'), ' ');
  final preview = compact.length > 80 ? '${compact.substring(0, 80)}…' : compact;
  return '$preview\n${broadcastFormatDate(enviadoEm)}';
}
