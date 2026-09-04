import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alimentar/data/alimentar_repository.dart';
import 'package:focux_app/features/alimentar/utils/alimentar_display.dart';

void main() {
  test('alimentarKcalLabel', () {
    expect(alimentarKcalLabel(1800), '1800 kcal/dia');
    expect(alimentarKcalLabel(null), 'Sem meta');
  });

  test('alimentarHubSubtitle junta freshness', () {
    expect(
      alimentarHubSubtitle(),
      'Nutrição prescrita para o aluno',
    );
    expect(
      alimentarHubSubtitle(freshness: 'há 1 min'),
      'Nutrição prescrita para o aluno · há 1 min',
    );
    expect(
      alimentarHubSubtitle(alunoNome: 'Ana', freshness: 'há 1 min'),
      'Nutrição prescrita para o aluno · Ana · há 1 min',
    );
  });

  test('alimentarPlanosMetricHint', () {
    expect(alimentarPlanosMetricHint(0), 'Crie o primeiro plano');
    expect(alimentarPlanosMetricHint(2), 'Toque para abrir as refeições');
  });

  test('alimentarDetailSubtitle e kcal da refeição', () {
    expect(alimentarDetailSubtitle(null), 'Refeições e macros do plano');
    expect(
      alimentarDetailSubtitle('há 1 min'),
      'Refeições e macros do plano · há 1 min',
    );
    expect(alimentarRefeicaoKcalLabel(450), '450 kcal');
    expect(alimentarRefeicaoKcalLabel(null), 'Sem kcal');
  });

  test('alimentarPlanoById e ícone', () {
    final planos = [
      PlanoAlimentar(id: 1, nome: 'Cutting'),
      PlanoAlimentar(id: 7, nome: 'Bulking', caloriasDia: 2800),
    ];
    expect(alimentarPlanoById(planos, 7)?.nome, 'Bulking');
    expect(alimentarPlanoById(planos, 99), isNull);
    expect(alimentarFxIcon(null), 'target');
    expect(alimentarFxIcon(1800), 'flame');
  });

  test('métricas e refeição do detalhe', () {
    expect(alimentarKcalMetricValue(null), '—');
    expect(alimentarKcalMetricValue(1800), '1800');
    expect(alimentarKcalMetricHint(null), 'Sem meta diária');
    expect(alimentarKcalMetricHint(1800), 'kcal por dia');
    expect(alimentarRefeicoesMetricValue(0), '0');
    expect(alimentarRefeicoesMetricHint(0), 'Adicione a primeira');
    expect(alimentarRefeicoesMetricHint(1), '1 refeição prescrita');
    expect(alimentarRefeicoesMetricHint(3), '3 refeições prescritas');
    expect(
      alimentarMacrosMetricValue(
        proteinaG: 180,
        carboidratoG: 250,
        gorduraG: 60,
      ),
      '180p · 250c · 60g',
    );
    expect(alimentarMacrosMetricValue(), '—');
    expect(
      alimentarMacrosMetricHint(
        proteinaG: 180,
        carboidratoG: 250,
        gorduraG: 60,
      ),
      'Proteína, carbo e gordura',
    );
    expect(alimentarMacrosMetricHint(), 'Sem macros no plano');
    expect(
      alimentarMacrosMetricHint(proteinaG: 180),
      'Macros parciais',
    );
    expect(alimentarRefeicaoTitle('Café', '07:30'), 'Café · 07:30');
    expect(alimentarRefeicaoTitle('Café', null), 'Café');
    expect(
      alimentarRefeicaoSubtitle(calorias: 450, proteinaG: 40),
      '450 kcal · 40g prot',
    );
    expect(alimentarRefeicaoSubtitle(), 'Sem macros nesta refeição');
    expect(alimentarCampoNumerico(null), '');
    expect(alimentarCampoNumerico(40), '40');
    expect(
      alimentarRefeicaoPayload(
        nome: ' Café ',
        horario: '07:30',
        calorias: '450',
        proteina: '',
        carbo: '50',
        gordura: '',
        alimentos: 'aveia',
      ),
      {
        'nomeRefeicao': 'Café',
        'horario': '07:30',
        'calorias': 450,
        'carboG': 50,
        'alimentos': 'aveia',
      },
    );
  });
}
