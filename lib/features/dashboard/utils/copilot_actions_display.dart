import '../data/command_center_data.dart';
import 'dashboard_command_copy.dart';

const copilotActionsStatusAberto = 'ABERTO';
const copilotActionsStatusAdiado = 'ADIADO';
const copilotActionsStatusConcluido = 'CONCLUIDO';

const copilotActionsStatusValues = [
  copilotActionsStatusAberto,
  copilotActionsStatusAdiado,
  copilotActionsStatusConcluido,
];

String copilotActionsStatusLabel(String status) {
  return switch (status) {
    copilotActionsStatusAdiado => 'Adiadas',
    copilotActionsStatusConcluido => 'Concluídas',
    _ => 'Abertas',
  };
}

String copilotActionsStatusChoiceLabel(
  String status,
  IaCommandActionsContagem? contagem,
) {
  final label = copilotActionsStatusLabel(status);
  if (contagem == null) return label;
  final n = switch (status) {
    copilotActionsStatusAdiado => contagem.adiadas,
    copilotActionsStatusConcluido => contagem.concluidas,
    _ => contagem.abertas,
  };
  return '$label $n';
}

String copilotActionsAdiarLabel() => 'Adiar 24h';

String copilotActionsConcluirLabel() => 'Concluir';

String copilotActionsReabrirLabel() => 'Reabrir';

String copilotActionsAtualizarLabel() => 'Atualizar';

String copilotActionsHelpTitle() => 'Tarefas';

String copilotActionsHelpSubtitle() =>
    'O que o Copiloto e os alertas pedem de você.';

const copilotActionsComoCalculamos =
    'Abertas são tarefas salvas do Copiloto e alertas automáticos ainda sem conclusão. Cada aluno aparece uma vez por alerta. Nada some sozinho.';

String copilotActionsEmptyTitle(String status) {
  return switch (status) {
    copilotActionsStatusAdiado => 'Nenhuma tarefa adiada',
    copilotActionsStatusConcluido => 'Nenhuma tarefa concluída',
    _ => 'Nenhuma tarefa aberta',
  };
}

String copilotActionsEmptySubtitle(String status) {
  return switch (status) {
    copilotActionsStatusAdiado =>
      'Quando uma ação for adiada, ela fica guardada aqui.',
    copilotActionsStatusConcluido =>
      'As tarefas resolvidas aparecem aqui para auditoria.',
    _ => 'Tarefas do Copiloto e alertas aparecem aqui quando pedem você.',
  };
}

/// Urgentes primeiro; a ordem do servidor vale dentro de cada grupo.
List<FilaAcaoResumo> copilotActionsOrdenadas(List<FilaAcaoResumo> itens) {
  int peso(FilaAcaoResumo a) => a.prioridade.trim().toUpperCase() == 'P0' ? 0 : 1;
  return [
    for (final p in [0, 1])
      for (final a in itens)
        if (peso(a) == p) a,
  ];
}

/// "Hoje" ou "Esta semana": nunca a sigla interna de prioridade.
String copilotActionsSelo(FilaAcaoResumo action) =>
    action.prioridade.trim().toUpperCase() == 'P0' ? 'Hoje' : 'Esta semana';

/// Título da linha: o nome do aluno, sem o prefixo interno.
String copilotActionsNome(FilaAcaoResumo action) =>
    dashboardRadarStudentName(action.titulo) ?? action.titulo.trim();

/// Motivo em frase: tira o nome repetido ("Hugo · mapa corporal").
String copilotActionsMotivo(FilaAcaoResumo action) {
  var texto = action.descricao.split('\n').first.trim();
  final corte = texto.indexOf(' · ');
  if (corte > 0) texto = texto.substring(corte + 3).trim();
  if (texto.isEmpty) return action.titulo.trim();
  if (texto.toLowerCase() == 'mapa corporal') return 'Mapa corporal pendente';
  return texto[0].toUpperCase() + texto.substring(1);
}

/// Leva direto ao que falta; sem destino próprio, ao aluno.
String copilotActionsDestino(FilaAcaoResumo action) {
  final id = action.alunoId;
  if (id == null) return action.acaoUrl;
  final texto = action.descricao.toLowerCase();
  if (texto.contains('mapa') || texto.contains('medida')) {
    return '/alunos/$id/evolucao';
  }
  if (texto.contains('feedback') || texto.contains('retomar')) {
    return '/alunos/$id/chat';
  }
  return action.acaoUrl;
}
