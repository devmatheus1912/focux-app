import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/utils/migracao_linha_classifier.dart';

void main() {
  test('nomes de pessoa', () {
    expect(migracaoClassificar('Maria Silva', null, null), MigracaoLinhaStatus.valido);
    expect(migracaoClassificar("José D'Ávila", null, null), MigracaoLinhaStatus.valido);
    expect(migracaoClassificar('Maria de Souza', null, null), MigracaoLinhaStatus.valido);
    expect(migracaoClassificar('Ana', null, null), MigracaoLinhaStatus.duvidoso);
  });

  test('contato valida mesmo com nome curto', () {
    expect(
      migracaoClassificar('João', 'joao@example.com', null),
      MigracaoLinhaStatus.valido,
    );
    expect(migracaoClassificar('', null, '(11) 99999-0000'), MigracaoLinhaStatus.valido);
  });

  test('linhas de documento são ignoradas', () {
    for (final linha in [
      'EMENTA: Conforme art. 10 § 19',
      'de janeiro de 2002 -Código Civil.',
      'AR',
      '1. Identificação da Autoridade',
      'processo de Certificação Digital disponível',
      'verdadeiras em relação aos signatários',
      '',
    ]) {
      expect(migracaoClassificar(linha, null, null), MigracaoLinhaStatus.ignorado, reason: linha);
    }
  });
}
