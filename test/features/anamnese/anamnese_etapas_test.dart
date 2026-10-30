import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/anamnese/utils/anamnese_etapas.dart';

void main() {
  test('PAR-Q pendente trava a primeira etapa', () {
    final parq = <String, bool?>{'a': true, 'b': null};
    expect(anamneseParqPendentes(parq), ['b']);
    expect(
      anamneseEtapaCompleta(
        AnamneseEtapa.saudeGeral,
        parq: parq,
        objetivo: '',
        dias: null,
      ),
      isFalse,
    );
  });

  test('histórico e hábitos não têm obrigatório', () {
    expect(
      anamneseEtapaCompleta(
        AnamneseEtapa.historico,
        parq: const {},
        objetivo: '',
        dias: null,
      ),
      isTrue,
    );
  });

  test('objetivos pedem objetivo e dias', () {
    bool completa(String objetivo, int? dias) => anamneseEtapaCompleta(
      AnamneseEtapa.objetivos,
      parq: const {},
      objetivo: objetivo,
      dias: dias,
    );
    expect(completa(' ', 3), isFalse);
    expect(completa('Saúde', null), isFalse);
    expect(completa('Saúde', 3), isTrue);
  });

  test('valor antigo livre não vira chip e não se perde', () {
    expect(anamneseChipDoValor('boa', anamneseQualidadeSonoOpcoes), 'Boa');
    expect(
      anamneseChipDoValor('acordo cansado', anamneseQualidadeSonoOpcoes),
      isNull,
    );
    expect(
      anamneseChipDoValor(
        'Fumo 5 por dia',
        anamneseTabagismoOpcoes,
        comDetalhe: 'Fumo',
      ),
      'Fumo',
    );
  });
}
