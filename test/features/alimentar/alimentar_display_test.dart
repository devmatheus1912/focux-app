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
}
