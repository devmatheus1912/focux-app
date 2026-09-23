import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_copiloto_display.dart';

void main() {
  test('copy do copiloto confirma gasto de cota e persistência', () {
    expect(iaCopilotoGerarLabel('Treino'), 'Gerar Treino');
    expect(iaCopilotoGerarConfirmTitle('Treino'), 'Gerar Treino com IA?');
    expect(iaCopilotoGerarConfirmMessage(), contains('cota de IA'));
    expect(iaCopilotoCriarTarefaLabel(), 'Criar tarefa');
    expect(iaCopilotoCriarTarefaConfirmTitle(), contains('Salvar tarefa'));
    expect(iaCopilotoAbrirAlunoLabel(), 'Abrir aluno');
    expect(iaCopilotoVerTarefaLabel(), 'Ver tarefa');
    expect(iaCopilotoComoCalculamos, contains('você pede'));
    expect(iaCopilotoRevisarProgressaoLabel(), 'Revisar progressão');
  });

  test('aplica só tipos executáveis do contrato existente', () {
    expect(
      iaCopilotoApplySpec(
        tipoAcao: 'TREINO',
        mensagemSugerida: 'Faz o check-in quando puder.',
      )?.backendTipo,
      'ENVIAR_PUSH',
    );
    expect(iaCopilotoApplySpec(tipoAcao: 'TREINO'), isNull);
    expect(
      iaCopilotoApplySpec(tipoAcao: 'CARGA')?.backendTipo,
      'REDUZIR_CARGA',
    );
    expect(
      iaCopilotoApplySpec(tipoAcao: 'REDUZIR_CARGA')?.backendTipo,
      'REDUZIR_CARGA',
    );
    expect(
      iaCopilotoApplySpec(
        tipoAcao: 'CONTATO',
        mensagemSugerida: 'Oi, Ana.',
      )?.backendTipo,
      'ENVIAR_PUSH',
    );
    expect(
      iaCopilotoApplySpec(tipoAcao: 'CONTATO'),
      isNull,
    );
    expect(
      iaCopilotoApplySpec(tipoAcao: 'MARCAR_RISCO')?.backendTipo,
      'MARCAR_RISCO',
    );
    expect(iaCopilotoApplySpec(tipoAcao: 'DIETA'), isNull);
    expect(
      iaCopilotoShouldReviewProgressao(mode: 'Progressão', apply: null),
      isTrue,
    );
    expect(
      iaCopilotoShouldReviewProgressao(
        mode: 'Progressão',
        apply: const IaCopilotoApplySpec(
          backendTipo: 'REDUZIR_CARGA',
          label: 'Aplicar',
        ),
      ),
      isFalse,
    );
  });
}
