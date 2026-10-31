import 'package:flutter/material.dart';

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
    _ => 'Nada pendente',
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

/// Resumo em uma linha: "3 abertas · 1 urgente".
String copilotActionsResumo(List<FilaAcaoResumo> acoes, {int? abertas}) {
  final urgentes = acoes.where(_urgente).length;
  final n = abertas ?? acoes.length;
  final total = n == 1 ? '1 aberta' : '$n abertas';
  if (urgentes == 0) return total;
  return '$total · $urgentes ${urgentes == 1 ? 'urgente' : 'urgentes'}';
}

bool _urgente(FilaAcaoResumo a) => a.prioridade.toUpperCase() == 'P0';

/// Urgente, Hoje e Depois, na ordem da lista. Grupo vazio não aparece.
List<(String, List<FilaAcaoResumo>)> copilotActionsPorGrupo(
  List<FilaAcaoResumo> acoes,
) {
  final ordem = copilotActionsOrdenadas(acoes);
  final hoje = ordem.where((a) => a.prioridade.toUpperCase() == 'P1').toList();
  final urgentes = ordem.where(_urgente).toList();
  final depois =
      ordem.where((a) => !_urgente(a) && a.prioridade.toUpperCase() != 'P1').toList();
  return [
    if (urgentes.isNotEmpty) ('Urgente', urgentes),
    if (hoje.isNotEmpty) ('Hoje', hoje),
    if (depois.isNotEmpty) ('Depois', depois),
  ];
}

/// Concluídas hoje, da mais recente para a mais antiga.
List<FilaAcaoResumo> copilotActionsFeitasHoje(
  List<FilaAcaoResumo> concluidas, {
  DateTime? now,
}) {
  final hoje = now ?? DateTime.now();
  DateTime? quando(FilaAcaoResumo a) =>
      DateTime.tryParse(a.resolvedAt ?? '')?.toLocal();
  final feitas =
      concluidas.where((a) {
        final q = quando(a);
        return q != null &&
            q.year == hoje.year &&
            q.month == hoje.month &&
            q.day == hoje.day;
      }).toList();
  feitas.sort((a, b) => quando(b)!.compareTo(quando(a)!));
  return feitas;
}

/// Ícone da tarefa sem aluno, pelo tipo.
IconData copilotActionsIcone(FilaAcaoResumo a) {
  final tipo = a.tipo.toUpperCase();
  if (tipo.contains('FINANC') || tipo.contains('COBRAN')) {
    return Icons.payments_outlined;
  }
  if (tipo.contains('AGENDA')) return Icons.event_outlined;
  return Icons.checklist_rounded;
}
