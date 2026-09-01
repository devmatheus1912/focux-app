import 'package:flutter_test/flutter_test.dart';
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

  test('alimentarDetailSubtitle e kcal da refeição', () {
    expect(alimentarDetailSubtitle(null), 'Refeições e macros do plano');
    expect(
      alimentarDetailSubtitle('há 1 min'),
      'Refeições e macros do plano · há 1 min',
    );
    expect(alimentarRefeicaoKcalLabel(450), '450 kcal');
    expect(alimentarRefeicaoKcalLabel(null), 'Sem kcal');
  });
}
