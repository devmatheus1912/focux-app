import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/utils/copilot_actions_display.dart';

const iaCopilotoComoCalculamos =
    'A IA só gera quando você pede. Nada entra no aluno sem revisão.';

String iaCopilotoCriarTarefaLabel() => 'Criar tarefa';

/// Aluno em destaque na abertura do Copiloto.
class CopilotoPrioridade {
  const CopilotoPrioridade({
    required this.alunoId,
    required this.nome,
    required this.motivo,
  });

  final int alunoId;
  final String nome;
  final String motivo;
}

/// Tarefas abertas viram no máximo [limite] alunos, sem repetir, urgentes antes.
List<CopilotoPrioridade> copilotoPrioridades(
  List<FilaAcaoResumo> abertas,
  Map<int, String> nomes, {
  int limite = 5,
}) {
  final ordenadas = copilotActionsOrdenadas(abertas);
  final vistos = <int>{};
  final out = <CopilotoPrioridade>[];
  for (final a in ordenadas) {
    final id = a.alunoId;
    if (id == null || !vistos.add(id)) continue;
    final nome = nomes[id];
    if (nome == null || nome.trim().isEmpty) continue;
    out.add(
      CopilotoPrioridade(
        alunoId: id,
        nome: nome.trim(),
        motivo: copilotActionsMotivo(a),
      ),
    );
    if (out.length == limite) break;
  }
  return out;
}

class IaCopilotoApplySpec {
  const IaCopilotoApplySpec({
    required this.backendTipo,
    required this.label,
    this.parametros,
  });

  final String backendTipo;
  final String label;
  final String? parametros;
}

IaCopilotoApplySpec? iaCopilotoApplySpec({
  required String? tipoAcao,
  String? mensagemSugerida,
}) {
  final tipo = tipoAcao?.trim().toUpperCase();
  if (tipo == null || tipo.isEmpty) return null;

  // Paridade com Aluno360: TREINO = check-in/push; carga só em CARGA explícita.
  if (tipo == 'CARGA' || tipo == 'REDUZIR_CARGA') {
    return const IaCopilotoApplySpec(
      backendTipo: 'REDUZIR_CARGA',
      label: 'Aplicar ajuste de carga (−15%)',
    );
  }

  if (tipo == 'TREINO' ||
      tipo == 'CONTATO' ||
      tipo == 'WEARABLE' ||
      tipo == 'ENVIAR_PUSH') {
    final msg = mensagemSugerida?.trim();
    if (msg == null || msg.isEmpty) return null;
    return IaCopilotoApplySpec(
      backendTipo: 'ENVIAR_PUSH',
      label:
          tipo == 'TREINO' ? 'Pedir check-in ao aluno' : 'Enviar mensagem ao aluno',
      parametros: msg,
    );
  }

  if (tipo == 'MARCAR_RISCO') {
    return const IaCopilotoApplySpec(
      backendTipo: 'MARCAR_RISCO',
      label: 'Registrar contato prioritário',
    );
  }

  return null;
}
