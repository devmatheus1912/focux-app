import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/winback/utils/winback_display.dart';

void main() {
  test('winbackTipoLabel em PT-BR', () {
    expect(winbackTiposConhecidos, [
      'ALUNO_INATIVO_7D',
      'ALUNO_INATIVO_30D',
      'ALUNO_INATIVO_60D',
    ]);
    expect(winbackTipoLabel('ALUNO_INATIVO_7D'), 'Inativo 7 dias');
    expect(winbackTipoLabel('aluno_inativo_30d'), 'Inativo 30 dias');
    expect(winbackTipoLabel('ALUNO_INATIVO_60D'), 'Inativo 60 dias');
    expect(winbackTipoLabel(''), 'Envio automático');
    expect(winbackTipoLabel(null), 'Envio automático');
    expect(winbackTipoLabel('TRIAL_EXPIRA'), 'TRIAL EXPIRA');
  });

  test('winback aluno, ícone e when', () {
    expect(winbackAlunoLabel('Ana'), 'Ana');
    expect(winbackAlunoLabel('  '), 'Aluno');
    expect(winbackAlunoLabel(null), 'Aluno');
    expect(winbackFxIcon('ALUNO_INATIVO_7D'), 'bell');
    expect(winbackFxIcon('ALUNO_INATIVO_30D'), 'trend');
    expect(winbackFxIcon('ALUNO_INATIVO_60D'), 'alert-triangle');
    expect(winbackWhenLabel('2026-09-01T14:05:00'), '01/09 14:05');
    expect(winbackWhenLabel(''), '—');
  });

  test('winbackSubtitle e hub', () {
    expect(
      winbackSubtitle(tipo: 'ALUNO_INATIVO_7D', mensagem: ''),
      'Inativo 7 dias',
    );
    expect(
      winbackSubtitle(
        tipo: 'ALUNO_INATIVO_7D',
        mensagem: '  Sentimos sua falta!  ',
      ),
      'Inativo 7 dias · Sentimos sua falta!',
    );
    expect(winbackCountLabel(0), 'Nenhum envio');
    expect(winbackCountLabel(1), '1 envio');
    expect(winbackCountLabel(4), '4 envios');
    expect(winbackComoCalculamos, contains('7º'));
    expect(winbackHubSubtitle(null), 'Log dos pushes automáticos');
    expect(
      winbackHubSubtitle('Atualizado agora'),
      'Log dos pushes automáticos · Atualizado agora',
    );
    expect(winbackSearchEmptyTitle(''), 'Nenhum envio ainda');
    expect(winbackSearchEmptyTitle('Ana'), 'Nenhum envio encontrado');
    expect(winbackSearchEmptySubtitle('Ana'), contains('nome'));
  });
}
