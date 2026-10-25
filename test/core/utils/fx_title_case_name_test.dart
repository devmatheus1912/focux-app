import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/fx_utils.dart';

void main() {
  group('fxTitleCaseName', () {
    test('capitaliza cada parte e mantém siglas de produto', () {
      expect(fxTitleCaseName('thales silva'), 'Thales Silva');
      expect(fxTitleCaseName('maria DA silva'), 'Maria Da Silva');
      expect(fxTitleCaseName('ia'), 'IA');
    });

    test('apara sobra de import nas pontas', () {
      expect(fxTitleCaseName('guilherme -'), 'Guilherme');
      expect(fxTitleCaseName('João -'), 'João');
      expect(fxTitleCaseName('- joão'), 'João');
      expect(fxTitleCaseName('• Maria Souza,'), 'Maria Souza');
      expect(fxTitleCaseName('«Ana Paula»'), 'Ana Paula');
    });

    test('tira número de lista no começo', () {
      expect(fxTitleCaseName('1. Maria Silva'), 'Maria Silva');
      expect(fxTitleCaseName('2) carlos lima'), 'Carlos Lima');
      expect(fxTitleCaseName('3 Ana Paula'), 'Ana Paula');
    });

    test('mantém acento e hífen no meio do nome', () {
      expect(fxTitleCaseName('ana-clara souza'), 'Ana-clara Souza');
      expect(fxTitleCaseName('JOSÉ AUGUSTO'), 'José Augusto');
    });

    test('sem letra nenhuma volta para "Aluno"', () {
      expect(fxTitleCaseName('---'), 'Aluno');
      expect(fxTitleCaseName('   '), 'Aluno');
      expect(fxTitleCaseName(''), 'Aluno');
    });
  });
}
