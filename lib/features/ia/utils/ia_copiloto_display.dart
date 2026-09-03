const iaCopilotoComoCalculamos =
    'A IA só gera quando você pede. Nada entra no aluno sem revisão.';

String iaCopilotoGerarLabel(String modeDisplay) => 'Gerar $modeDisplay';

String iaCopilotoGerarConfirmTitle(String modeDisplay) =>
    'Gerar $modeDisplay com IA?';

String iaCopilotoGerarConfirmMessage() =>
    'Consome cota de IA. Nada é aplicado no aluno automaticamente.';

String iaCopilotoGerarConfirmLabel(String modeDisplay) =>
    iaCopilotoGerarLabel(modeDisplay);

String iaCopilotoCriarTarefaLabel() => 'Criar tarefa';

String iaCopilotoCriarTarefaConfirmTitle() => 'Salvar tarefa no Copiloto?';

String iaCopilotoCriarTarefaConfirmMessage() =>
    'A tarefa entra na lista do Copiloto. Você pode revisar depois.';

String iaCopilotoMaisAcoesLabel() => 'Mais ações';

String iaCopilotoVerTarefaLabel() => 'Ver tarefa';

String iaCopilotoAbrirAlunoLabel() => 'Abrir aluno';

String iaCopilotoRevisarProgressaoLabel() => 'Revisar progressão';

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

  if (tipo == 'TREINO' || tipo == 'REDUZIR_CARGA') {
    return const IaCopilotoApplySpec(
      backendTipo: 'REDUZIR_CARGA',
      label: 'Aplicar ajuste de carga (−15%)',
    );
  }

  if (tipo == 'CONTATO' || tipo == 'WEARABLE' || tipo == 'ENVIAR_PUSH') {
    final msg = mensagemSugerida?.trim();
    if (msg == null || msg.isEmpty) return null;
    return IaCopilotoApplySpec(
      backendTipo: 'ENVIAR_PUSH',
      label: 'Enviar notificação ao aluno',
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

bool iaCopilotoShouldReviewProgressao({
  required String mode,
  required IaCopilotoApplySpec? apply,
}) {
  if (apply != null) return false;
  final normalized = mode.trim().toLowerCase();
  return normalized == 'progressão' ||
      normalized == 'progressao' ||
      normalized == 'progresso';
}
