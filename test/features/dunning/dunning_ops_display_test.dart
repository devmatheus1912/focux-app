import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dunning/utils/dunning_ops_display.dart';

void main() {
  test('dunningContextoLabel', () {
    expect(dunningContextoLabel('ALUNO_MENSALIDADE'), 'Mensalidade');
    expect(dunningContextoLabel('FOCUX_SUBSCRIPTION'), 'Assinatura Focux');
    expect(dunningContextoLabel(''), 'Pagamento');
    expect(dunningContextoLabel('OUTRO'), 'OUTRO');
  });

  test('dunningFalhaTitulo e subtitle', () {
    expect(dunningTentativaLabel(0), 'Ainda sem retentativa');
    expect(dunningTentativaLabel(1), 'Tentativa 1');
    expect(dunningTentativaLabel(3), 'Tentativa 3');
    expect(
      dunningFalhaTitulo('Ana Silva', 'ALUNO_MENSALIDADE'),
      'Ana Silva',
    );
    expect(
      dunningFalhaTitulo(null, 'FOCUX_SUBSCRIPTION'),
      'Assinatura Focux',
    );
    expect(
      dunningFalhaSubtitle(
        contexto: 'ALUNO_MENSALIDADE',
        alunoNome: 'Ana Silva',
        motivo: 'Cartao recusado',
        tentativa: 1,
      ),
      'Mensalidade · Cartao recusado · Tentativa 1',
    );
    expect(
      dunningFalhaSubtitle(
        contexto: 'FOCUX_SUBSCRIPTION',
        motivo: '  ',
        tentativa: 2,
      ),
      'Tentativa 2',
    );
  });

  test('dunningTaxaFraca e recuperadas', () {
    expect(dunningTaxaFraca(0, 0), isFalse);
    expect(dunningTaxaFraca(49.9, 10), isTrue);
    expect(dunningTaxaFraca(50, 10), isFalse);
    expect(dunningRecuperadasLabel(7, 10), '7 de 10');
    expect(dunningRateLabel(70), '70.0%');
    expect(dunningFalhasPreview([1, 2, 3, 4]), [1, 2, 3]);
    expect(dunningComoCalculamos, contains('Recuperadas'));
    expect(dunningHasAluno(8), isTrue);
    expect(dunningHasAluno(null), isFalse);
    expect(dunningIsAssinaturaFocux('FOCUX_SUBSCRIPTION'), isTrue);
    expect(dunningIsAssinaturaFocux('ALUNO_MENSALIDADE'), isFalse);
  });
}
