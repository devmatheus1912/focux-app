import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/trilhas/utils/trilhas_display.dart';

void main() {
  test('trilhaMetaTipoLabel em PT-BR', () {
    expect(trilhaMetaTipos, ['TREINOS', 'PESO', 'MEDIDA', 'CUSTOMIZADO']);
    expect(trilhaMetaTipoLabel('TREINOS'), 'Número de treinos');
    expect(trilhaMetaTipoLabel('peso'), 'Meta de peso');
    expect(trilhaMetaTipoLabel('MEDIDA'), 'Meta de medida');
    expect(trilhaMetaTipoLabel('CUSTOMIZADO'), 'Customizado');
    expect(trilhaMetaTipoLabel(''), 'Tipo de meta');
    expect(trilhaMetaTipoLabel(null), 'Tipo de meta');
    expect(trilhaMetaTipoLabel('OUTRO'), 'OUTRO');
  });

  test('trilha status, percentual e hub subtitle', () {
    expect(trilhaStatusLabel(true), 'Concluída');
    expect(trilhaStatusLabel(false), 'Em andamento');
    expect(trilhaPercentLabel(70.4), '70%');
    expect(trilhaHubSubtitle(alunoNome: 'Ana'), 'Ana');
    expect(
      trilhaHubSubtitle(alunoNome: '  ', freshness: 'Atualizado agora'),
      'Aluno · Atualizado agora',
    );
  });
}
