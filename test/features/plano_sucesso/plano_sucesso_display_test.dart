import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/plano_sucesso/plano_sucesso_display.dart';
import 'package:focux_app/features/plano_sucesso/plano_sucesso_model.dart';

void main() {
  test('percentual e hint de progresso', () {
    expect(planoSucessoPercentLabel(0, 0), '0%');
    expect(planoSucessoPercentLabel(1, 4), '25%');
    expect(planoSucessoProgressHint(0, 0), 'Sem etapas ainda');
    expect(planoSucessoProgressHint(2, 4), '2 de 4 etapas');
  });

  test('revisão e metric hint', () {
    expect(
      planoSucessoRevisaoLabel(DateTime(2026, 9, 3)),
      '03/09',
    );
    expect(
      planoSucessoMetricHint(
        done: 1,
        total: 4,
        proximaRevisao: DateTime(2026, 9, 3),
      ),
      '1 de 4 etapas · revisão 03/09',
    );
  });

  test('próximo marco e sticky', () {
    final pendente = MarcoSucesso(id: 2, titulo: 'Check-in', atingido: false);
    final marcos = [
      MarcoSucesso(id: 1, titulo: 'Anamnese', atingido: true),
      pendente,
    ];
    expect(planoSucessoProximoMarco(marcos), same(pendente));
    expect(planoSucessoProximoMarco(const []), isNull);
    expect(planoSucessoStickyLabel(null), 'Criar plano');
    expect(planoSucessoStickyLabel(pendente), 'Marcar etapa');
    expect(
      planoSucessoMarcoSubtitle(atingido: true, atual: false),
      'Etapa concluída',
    );
    expect(
      planoSucessoMarcoSubtitle(atingido: false, atual: true),
      'Próxima etapa',
    );
    expect(
      planoSucessoMarcoSubtitle(atingido: false, atual: false),
      'Pendente',
    );
  });
}
