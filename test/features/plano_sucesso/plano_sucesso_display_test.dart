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
    expect(
      planoSucessoStickyLabel(hasPlano: false, proximo: null),
      'Criar plano',
    );
    expect(
      planoSucessoStickyLabel(hasPlano: true, proximo: pendente),
      'Marcar etapa',
    );
    expect(
      planoSucessoStickyLabel(hasPlano: true, proximo: null),
      'Remarcar revisão',
    );
    expect(planoSucessoRevisaoIso(DateTime(2026, 9, 3)), '2026-09-03');
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
    expect(
      planoSucessoHubSubtitle(base: 'Metas e prazos do aluno'),
      'Metas e prazos do aluno',
    );
    expect(
      planoSucessoHubSubtitle(
        base: 'Emagrecer 8 kg',
        freshness: 'Atualizado agora',
      ),
      'Emagrecer 8 kg · Atualizado agora',
    );
    expect(planoSucessoEtapasValue(1, 4), '1/4');
    expect(
      planoSucessoEtapasHint(done: 0, total: 0, proximo: null),
      'Nenhuma etapa ainda',
    );
    expect(
      planoSucessoEtapasHint(done: 4, total: 4, proximo: null),
      'Todas as etapas feitas',
    );
    expect(
      planoSucessoEtapasHint(done: 1, total: 4, proximo: pendente),
      '1 de 4 · próxima etapa',
    );
    expect(planoSucessoRevisaoMetricValue(null), '—');
    expect(
      planoSucessoRevisaoMetricValue(DateTime(2026, 9, 3)),
      '03/09',
    );
    expect(planoSucessoRevisaoMetricHint(null), 'Sem data de revisão');
    expect(
      planoSucessoRevisaoMetricHint(DateTime(2026, 9, 3)),
      'Próxima revisão',
    );
  });

  test('opções de revisão são horizontes fixos', () {
    final ops = planoSucessoRevisaoOpcoes(DateTime(2026, 9, 4));
    expect(ops.map((o) => o.dias).toList(), planoSucessoRevisaoHorizontes);
    expect(ops.first.label, 'Em 7 dias');
    expect(ops.first.subtitle, '11/09');
    expect(ops.first.data, DateTime(2026, 9, 11));
    expect(
      planoSucessoRevisaoOpcaoSelecionada(
        opcoes: ops,
        atual: DateTime(2026, 9, 18),
      ),
      DateTime(2026, 9, 18),
    );
    expect(
      planoSucessoRevisaoOpcaoSelecionada(
        opcoes: ops,
        atual: DateTime(2026, 10, 1),
      ),
      isNull,
    );
  });
}
