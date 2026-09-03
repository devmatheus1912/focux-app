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
      'Hidratação',
    );
    expect(habitoSubtitle(descricao: '  ', metaSemanal: 7), 'Meta semanal: 7x');
    expect(habitoMetaValue(5), '5x');
  });

  test('habitoCompliance não expõe id', () {
    expect(habitoComplianceLabel('Ana'), 'Ana');
    expect(habitoComplianceLabel('  '), 'Aluno');
    expect(habitoComplianceLabel(null), 'Aluno');
    expect(habitoComplianceValue(80), '80%');
    expect(habitoComplianceSubtitle(1), '1 check na semana');
    expect(habitoComplianceSubtitle(4), '4 checks na semana');
    expect(habitoComplianceFxIcon(80), 'circle-check');
    expect(habitoComplianceFxIcon(50), 'trend');
    expect(habitoComplianceFxIcon(10), 'alert-triangle');
    expect(habitoComplianceDanger(39), isTrue);
    expect(habitoComplianceDanger(40), isFalse);
  });

  test('habitoHubSubtitle junta freshness', () {
    expect(habitoHubSubtitle(null), 'Coaching diário e aderência');
    expect(
      habitoHubSubtitle('há 1 min'),
      'Coaching diário e aderência · há 1 min',
    );
    expect(habitoCountLabel(0), 'Nenhum hábito');
    expect(habitoCountLabel(1), '1 hábito');
    expect(habitoCountLabel(3), '3 hábitos');
    expect(habitoComoCalculamos, contains('checks'));
    expect(habitoComplianceEmptyTitle(''), 'Sem dados ainda');
    expect(habitoComplianceEmptyTitle('ana'), 'Nenhum aluno encontrado');
    expect(habitoComplianceEmptySubtitle('ana'), contains('nome'));
  });
}
