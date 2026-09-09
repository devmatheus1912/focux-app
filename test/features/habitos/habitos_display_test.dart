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
  });

  test('habitoCountLabel cobre vazio e plural', () {
    expect(habitoCountLabel(0), 'Nenhum hábito');
    expect(habitoCountLabel(1), '1 hábito');
    expect(habitoCountLabel(3), '3 hábitos');
    expect(
      habitoAlunoSubtitle(
        descricao: 'Água',
        feitosNaSemana: 3,
        metaSemanal: 7,
      ),
      'Água · 3/7 na semana',
    );
    expect(
      habitoMatchesQuery(titulo: 'Beber água', query: 'beber'),
      isTrue,
    );
    expect(
      habitoMatchesQuery(titulo: 'Sono', descricao: '8h', query: 'cardio'),
      isFalse,
    );
    expect(habitoComoCalculamos, contains('checks'));
    expect(habitoComplianceEmptyTitle(''), 'Sem dados ainda');
    expect(habitoComplianceEmptyTitle('ana'), 'Nenhum aluno encontrado');
    expect(habitoComplianceEmptySubtitle('ana'), contains('nome'));
    expect(habitoAlunoTodosLabel, 'Todos os alunos');
    expect(habitoAlcanceLabel(null), 'Todos os alunos');
    expect(habitoAlcanceLabel(9), 'Aluno específico');
    expect(
      habitoDetalheMessage(descricao: 'Hidratação', metaSemanal: 7),
      contains('Hidratação'),
    );
    expect(
      habitoDetalheMessage(metaSemanal: 5),
      contains('Meta semanal: 5x'),
    );
    expect(habitoDetailPath(4), '/habitos/4');
    expect(habitoAlunoDetailPath(4), '/aluno/habitos/4');
    expect(habitoStreakHint(0), 'Sem sequência');
    expect(habitoStreakHint(1), '1 dia seguido');
    expect(habitoFeitosValue(3, 7), '3/7');
    expect(habitoFeitosHint(feitos: 7, meta: 7), 'Meta da semana ok');
    expect(habitoStickyPersonal(), 'Desativar hábito');
    expect(habitoStickyAluno(false), 'Marcar hoje');
    expect(habitoStickyAluno(true), 'Desmarcar hoje');
    expect(habitoDetalheSecoes, hasLength(2));
    expect(
      habitoDetailSubtitle(metaSemanal: 7, alunoId: null),
      'Meta 7x · Todos os alunos',
    );
    expect(
      habitoDetailSubtitle(metaSemanal: 7, alunoId: 3, ativo: false),
      'Desativado · Meta 7x · Aluno específico',
    );
    expect(habitoDesativadoChip(), 'Desativado');
    expect(habitoLembreteLine(null), 'Sem horário de lembrete');
    expect(habitoLembreteLine('  '), 'Sem horário de lembrete');
    expect(habitoLembreteLine('08:00'), 'Lembrete às 08:00');
    expect(habitoChecksLine(null), '');
    expect(habitoChecksLine(const []), 'Nenhum check ainda');
    expect(
      habitoChecksLine([
        HabitoCheckDia(data: DateTime(2026, 9, 7), feito: true),
        HabitoCheckDia(data: DateTime(2026, 9, 6), feito: false),
      ]),
      'Feitos: 07/09',
    );
    expect(
      habitoPatchCheckHoje(
        [HabitoCheckDia(data: DateTime(2026, 9, 6), feito: true)],
        true,
        now: DateTime(2026, 9, 7),
      )?.first.data,
      DateTime(2026, 9, 7),
    );
  });
}
