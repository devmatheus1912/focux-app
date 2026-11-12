import 'package:flutter/material.dart';

import '../../../l10n/pt.dart';
import '../data/command_center_data.dart';
import 'dashboard_command_copy.dart';
import '../../../core/theme/fx_icons.dart';

const copilotActionsStatusAberto = 'ABERTO';
const copilotActionsStatusAdiado = 'ADIADO';
const copilotActionsStatusConcluido = 'CONCLUIDO';

String copilotActionsStatusLabel(String status) {
  return switch (status) {
    copilotActionsStatusAdiado => 'Adiadas',
    copilotActionsStatusConcluido => 'Feitas',
    _ => 'Abertas',
  };
}

String copilotActionsAdiarLabel() => 'Adiar 24h';

String copilotActionsConcluirLabel() => 'Concluir';

String copilotActionsReabrirLabel() => 'Reabrir';

String copilotActionsAtualizarLabel() => 'Atualizar';

String copilotActionsHelpTitle() => 'Tarefas';

String copilotActionsHelpSubtitle() =>
    'O que a IA Focux e os alertas pedem de você.';

const copilotActionsComoCalculamos =
    'Abertas são tarefas salvas da IA Focux e alertas automáticos ainda sem conclusão. Cada aluno aparece uma vez por alerta. Nada some sozinho.';

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
    _ => 'Tarefas da IA Focux e alertas aparecem aqui quando pedem você.',
  };
}

/// Urgentes primeiro; a ordem do servidor vale dentro de cada grupo.
List<FilaAcaoResumo> copilotActionsOrdenadas(List<FilaAcaoResumo> itens) {
  int peso(FilaAcaoResumo a) =>
      a.prioridade.trim().toUpperCase() == 'P0' ? 0 : 1;
  return [
    for (final p in [0, 1])
      for (final a in itens)
        if (peso(a) == p) a,
  ];
}

/// Prazo de uma prioridade: grupo em Tarefas, pílula e se a pílula é aviso.
/// Uma tabela só para Tarefas, a folha de criar tarefa e o Copiloto.
typedef CopilotPrazo = ({String grupo, String? selo, bool aviso});

CopilotPrazo copilotActionsPrazo(String prioridade) => switch (prioridade
    .trim()
    .toUpperCase()) {
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

/// Linha da tarefa com o aluno no título: o motivo vira o que fazer, sem
/// repetir o nome ("Revisar ação do copiloto de Julio" → "Revisar a ação da
/// IA Focux").
String copilotActionsMotivoParaPersonal(
  FilaAcaoResumo action, {
  String? nomeAluno,
}) {
  final titulo = action.titulo.trim();
  final nome = nomeAluno?.trim() ?? '';
  final tituloEhNome =
      nome.isNotEmpty && titulo.toLowerCase() == nome.toLowerCase();
  if (nome.isEmpty ||
      tituloEhNome ||
      copilotActionsNome(action) == titulo &&
          titulo.toLowerCase().startsWith(
            nome.toLowerCase().split(' ').first,
          )) {
    return copilotActionsMotivo(action);
  }
  var t = titulo.replaceAll(
    RegExp(' (de|do|da) ${RegExp.escape(nome)}\$', caseSensitive: false),
    '',
  );
  t = t.replaceAll(RegExp('copiloto', caseSensitive: false), 'IA Focux');
  t = t.replaceFirst(
    RegExp('ação do IA Focux', caseSensitive: false),
    'a ação da IA Focux',
  );
  return t.isEmpty ? copilotActionsMotivo(action) : t;
}

/// "Feita hoje", "Feita ontem", "Feita há 3 dias".
String copilotActionsFeitaHa(FilaAcaoResumo a, {DateTime? agora}) {
  final quando =
      DateTime.tryParse(a.resolvedAt ?? a.updatedAt ?? '')?.toLocal();
  if (quando == null) return 'Feita';
  final hoje = agora ?? DateTime.now();
  final dias =
      DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
      ).difference(DateTime(quando.year, quando.month, quando.day)).inDays;
  if (dias <= 0) return 'Feita hoje';
  if (dias == 1) return 'Feita ontem';
  return 'Feita há $dias dias';
}

/// Mesma tarefa (aluno + o que fazer) duas vezes: fica a mais recente.
List<FilaAcaoResumo> copilotActionsSemRepetir(List<FilaAcaoResumo> itens) {
  final vistos = <String>{};
  return [
    for (final a in itens)
      if (vistos.add('${a.alunoId}|${copilotActionsMotivo(a).toLowerCase()}'))
        a,
  ];
}

/// Motivo em frase: tira o nome repetido ("Hugo · mapa corporal").
String copilotActionsMotivo(FilaAcaoResumo action) {
  var texto = action.descricao.split('\n').first.trim();
  final corte = texto.indexOf(' · ');
  if (corte > 0) texto = texto.substring(corte + 3).trim();
  if (texto.isEmpty) return action.titulo.trim();
  if (texto.toLowerCase() == 'mapa corporal') {
    return 'Falta medir o mapa corporal';
  }
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
    grupos
        .putIfAbsent(copilotActionsPrazo(a.prioridade).grupo, () => [])
        .add(a);
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
