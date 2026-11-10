import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_copiloto_display.dart';

void main() {
  test('copy do copiloto confirma gasto de cota e persistência', () {
    expect(iaCopilotoCriarTarefaLabel(), 'Criar tarefa');
    expect(iaCopilotoComoCalculamos, contains('você pede'));
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
    // Carga abre a revisão; nunca o corte de −15% (seria "reduzir" para
    // uma recomendação de "aumentar intensidade").
    final carga = iaCopilotoApplySpec(tipoAcao: 'CARGA', alunoId: 7);
    expect(carga?.backendTipo, isNull);
    expect(carga?.rota, '/alunos/7/ia/progressao');
    expect(carga?.label, 'Ajustar cargas');
    expect(
      iaCopilotoApplySpec(tipoAcao: 'MEDIDA', alunoId: 7)?.rota,
      '/alunos/7/evolucao',
    );
    expect(iaCopilotoApplySpec(tipoAcao: 'CARGA'), isNull);
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
  });

}
