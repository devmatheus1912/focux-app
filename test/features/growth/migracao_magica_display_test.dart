import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/utils/migracao_magica_display.dart';

void main() {
  test('copy da migração confirma análise e gravação', () {
    expect(migracaoIniciarLabel(), 'Analisar texto');
    expect(migracaoIniciarConfirmMessage(), contains('Nada é salvo'));
    expect(migracaoSalvarLabel(3), 'Confirmar e salvar 3 alunos');
    expect(migracaoSalvarConfirmTitle(3), contains('3 alunos'));
    expect(migracaoDiscardConfirmLabel(), 'Sair');
  });
}
