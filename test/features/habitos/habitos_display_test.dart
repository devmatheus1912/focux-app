import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/habitos/utils/habitos_display.dart';

void main() {
  test('habitoTemplateLabel e value', () {
    expect(
      habitoTemplateLabel(titulo: 'Beber água', icone: '💧'),
      '💧 Beber água',
    );
    expect(habitoTemplateLabel(titulo: '  ', icone: '💧'), '💧');
    expect(habitoTemplateLabel(titulo: 'Caminhar'), 'Caminhar');
    expect(habitoTemplateValue(null), 'Personalizado');
    expect(habitoTemplateValue('  '), 'Personalizado');
    expect(
      habitoTemplateValue('Beber água', icone: '💧'),
      '💧 Beber água',
    );
  });

  test('habitoSubtitle prefere descricao', () {
    expect(
      habitoSubtitle(descricao: 'Hidratação', metaSemanal: 7),
      'Hidratação · Todos os alunos',
    );
    expect(
      habitoSubtitle(descricao: '  ', metaSemanal: 7, alunoId: 3),
      'Meta semanal: 7x · Aluno específico',
    );
    expect(habitoMetaValue(5), '5x');
  });


}
