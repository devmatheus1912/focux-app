import 'package:flutter/material.dart';

import '../../../l10n/pt.dart';
import '../data/command_center_data.dart';
import 'dashboard_command_copy.dart';
import '../../../core/theme/fx_icons.dart';

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
    _ => ptS.tarefasNadaPendente,
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

/// Prazo de uma prioridade: grupo em Tarefas, pílula e se a pílula é aviso.
/// Uma tabela só para Tarefas, a folha de criar tarefa e o Copiloto.
typedef CopilotPrazo = ({String grupo, String? selo, bool aviso});

CopilotPrazo copilotActionsPrazo(String prioridade) =>
    switch (prioridade.trim().toUpperCase()) {
      'P0' => (grupo: ptS.tarefasGrupoUrgente, selo: 'Hoje', aviso: true),
      'P1' => (grupo: 'Esta semana', selo: 'Esta semana', aviso: false),
      _ => (grupo: ptS.tarefasGrupoDepois, selo: null, aviso: false),
    };

/// "Hoje" ou "Esta semana": nunca a sigla interna de prioridade.
String copilotActionsSelo(FilaAcaoResumo action) =>
    copilotActionsPrazo(action.prioridade).selo ?? '';

/// Título da linha: o nome do aluno, sem o prefixo interno.
String copilotActionsNome(FilaAcaoResumo action) {
  final titulo = action.titulo.trim();
  final copiloto = RegExp(r'^Revisar treino de (.+)$').firstMatch(titulo);
  if (copiloto != null) return copiloto.group(1)!.trim();
  return dashboardRadarStudentName(titulo) ?? titulo;
}

/// Por que o aluno precisa de atenção: o motivo salvo na tarefa do Copiloto
/// ("…\n\nMotivo: …"), senão a primeira linha da descrição.
String copilotActionsPorque(FilaAcaoResumo action) {
  final partes = action.descricao.split('\n\nMotivo: ');
  if (partes.length > 1 && partes.last.trim().isNotEmpty) {
    return partes.last.trim();
  }
  return copilotActionsMotivo(action);
}

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

/// Urgente, Esta semana e Depois, na ordem da lista ([copilotActionsPrazo]).
/// Grupo vazio não aparece.
List<(String, List<FilaAcaoResumo>)> copilotActionsPorGrupo(
  List<FilaAcaoResumo> acoes,
) {
  final grupos = <String, List<FilaAcaoResumo>>{};
  for (final a in copilotActionsOrdenadas(acoes)) {
    grupos.putIfAbsent(copilotActionsPrazo(a.prioridade).grupo, () => []).add(a);
  }
  return [
    for (final g in [
      ptS.tarefasGrupoUrgente,
      copilotActionsPrazo('P1').grupo,
      ptS.tarefasGrupoDepois,
    ])
      if (grupos[g] case final itens?) (g, itens),
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
    return FxIcons.pagamento;
  }
  if (tipo.contains('AGENDA')) return FxIcons.calendario;
  return FxIcons.checklist;
}

/// O verbo da linha, vindo da tarefa ("Responder", "Cobrar").
String copilotActionsVerbo(FilaAcaoResumo a) {
  final cta = a.ctaLabel.trim();
  return cta.isEmpty ? ptS.tarefasVerboAbrir : cta;
}
