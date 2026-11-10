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
        motivo: copilotActionsPorque(a),
      ),
    );
    if (out.length == limite) break;
  }
  return out;
}

/// O que o botão de uma recomendação faz: abrir uma tela do app ou executar
/// uma ação no backend (com confirmação).
class IaCopilotoApplySpec {
  const IaCopilotoApplySpec({
    required this.label,
    this.backendTipo,
    this.rota,
    this.parametros,
  });

  final String label;

  /// Ação executada no backend (`ENVIAR_PUSH`, `MARCAR_RISCO`, `REDUZIR_CARGA`).
  final String? backendTipo;

  /// Tela que o botão abre (carga, medida). Não executa nada sozinho.
  final String? rota;
  final String? parametros;

  bool get abreTela => rota != null;
}

/// Ação de uma recomendação ou da próxima ação.
///
/// `CARGA` abre Ajustar cargas, onde o personal revisa exercício por
/// exercício: "aumentar intensidade" nunca vira o corte de −15%. O corte só
/// existe para `REDUZIR_CARGA` explícito.
IaCopilotoApplySpec? iaCopilotoApplySpec({
  required String? tipoAcao,
  String? mensagemSugerida,
  int? alunoId,
}) {
  final tipo = tipoAcao?.trim().toUpperCase();
  if (tipo == null || tipo.isEmpty) return null;

  switch (tipo) {
    case 'CARGA':
      if (alunoId == null) return null;
      return IaCopilotoApplySpec(
        label: 'Ajustar cargas',
        rota: '/alunos/$alunoId/ia/progressao',
      );
    case 'MEDIDA':
      if (alunoId == null) return null;
      return IaCopilotoApplySpec(
        label: 'Conferir medida',
        rota: '/alunos/$alunoId/evolucao',
      );
    case 'REDUZIR_CARGA':
      return const IaCopilotoApplySpec(
        backendTipo: 'REDUZIR_CARGA',
        label: 'Aplicar ajuste de carga (−15%)',
      );
    case 'MARCAR_RISCO':
      return const IaCopilotoApplySpec(
        backendTipo: 'MARCAR_RISCO',
        label: 'Registrar contato prioritário',
      );
  }

  // Mensagem pronta ao aluno: treino vira pedido de check-in.
  final msg = mensagemSugerida?.trim();
  if (msg == null || msg.isEmpty) return null;
  return IaCopilotoApplySpec(
    backendTipo: 'ENVIAR_PUSH',
    label: tipo == 'TREINO' ? 'Pedir check-in' : 'Enviar mensagem',
    parametros: msg,
  );
}

/// Texto de custo junto de "Analisar" e "Refazer".
String iaCopilotoCustoAnalise() => 'Usa 1 da sua cota de IA.';
