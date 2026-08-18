import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/treinos_list_labels.dart';

void main() {
  test('readyPlans pluralizes correctly', () {
    expect(TreinosListLabels.readyPlans(1), '1 plano pronto para uso.');
    expect(TreinosListLabels.readyPlans(3), '3 planos prontos para uso.');
  });

  test('readyCount and templateCount pluralize correctly', () {
    expect(TreinosListLabels.readyCount(1), '1 pronto');
    expect(TreinosListLabels.readyCount(2), '2 prontos');
    expect(TreinosListLabels.templateCount(1), '1 template');
    expect(TreinosListLabels.templateCount(4), '4 templates');
  });

  test('cardMeta is honest: counts or em montagem, never fake duration', () {
    expect(
      TreinosListLabels.cardMeta(
        pronto: true,
        exercises: 7,
        series: 26,
        nivel: 'INTERMEDIARIO',
      ),
      '7 exercícios · 26 séries · Intermediário',
    );
    expect(
      TreinosListLabels.cardMeta(
        pronto: false,
        exercises: 0,
        series: 0,
        nivel: null,
      ),
      'Em montagem',
    );
  });

  group('empty state copy', () {
    test('uses library wording without aluno context', () {
      expect(TreinosListLabels.emptyTitle(), 'Sua biblioteca começa aqui');
      expect(TreinosListLabels.emptySubtitle(), contains('plano base'));
    });

    test('uses aluno first name when a student is in context', () {
      expect(
        TreinosListLabels.emptyTitle(alunoNome: '  Ana Paula Souza '),
        'Nenhum treino atribuído',
      );
      expect(
        TreinosListLabels.emptySubtitle(alunoNome: '  Ana Paula Souza '),
        'Atribua um plano a Ana ou crie um treino e vincule ao perfil.',
      );
    });

    test('falls back to library wording for blank aluno name', () {
      expect(
        TreinosListLabels.emptyTitle(alunoNome: '   '),
        'Sua biblioteca começa aqui',
      );
    });
  });

  test('selection and delete copy stay honest', () {
    expect(TreinosListLabels.selectionCount(1), '1 selecionado');
    expect(TreinosListLabels.selectionCount(2), '2 selecionados');
    expect(
      TreinosListLabels.deleteTitle(unlinkOnly: false, count: 2),
      'Remover treinos?',
    );
    expect(
      TreinosListLabels.deleteBody(unlinkOnly: false, count: 2, name: null),
      '2 treinos selecionados saem da biblioteca. Históricos já concluídos continuam preservados.',
    );
    expect(TreinosListLabels.deleteConfirmLabel(unlinkOnly: false), 'Remover');
    expect(
      TreinosListLabels.deleteConfirmLabel(unlinkOnly: true),
      'Desvincular',
    );
  });
}
