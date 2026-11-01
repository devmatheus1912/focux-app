import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/habitos/data/habito_repository.dart';
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
    expect(
      habitoFocusCompliance([
        ComplianceItem(
          alunoId: 1,
          alunoNome: 'Ana',
          checksSemana: 2,
          compliancePct: 80,
        ),
        ComplianceItem(
          alunoId: 2,
          alunoNome: 'Bia',
          checksSemana: 0,
          compliancePct: 20,
        ),
      ])?.alunoId,
      2,
    );
    expect(habitoFocusCompliance(const []), isNull);
    expect(
      habitoComplianceListExcludingFocus(
        [
          ComplianceItem(
            alunoId: 1,
            alunoNome: 'Ana',
            checksSemana: 2,
            compliancePct: 80,
          ),
          ComplianceItem(
            alunoId: 2,
            alunoNome: 'Bia',
            checksSemana: 0,
            compliancePct: 20,
          ),
        ],
        ComplianceItem(
          alunoId: 2,
          alunoNome: 'Bia',
          checksSemana: 0,
          compliancePct: 20,
        ),
      ).map((e) => e.alunoId),
      [1],
    );
  });

}
