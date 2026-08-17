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
}
