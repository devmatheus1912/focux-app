import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/winback/data/winback_repository.dart';
import 'package:focux_app/features/winback/utils/winback_display.dart';

void main() {
  test('winbackTipoLabel em PT-BR', () {
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
    expect(
      winbackWhenLabel('2026-09-01T14:05:00', now: DateTime(2026, 9, 24)),
      '01/09 às 14:05',
    );
    expect(winbackComoCalculamos, contains('não recebe'));
    expect(winbackWhenLabel(''), '—');
  });

  test('winbackSubtitle e hub', () {
    expect(
      winbackSubtitle(tipo: 'ALUNO_INATIVO_30D', mensagem: ''),
      'Inativo 30 dias',
    );
    expect(
      winbackSubtitle(
        tipo: 'ALUNO_INATIVO_30D',
        mensagem: '  Sentimos sua falta!  ',
      ),
      'Inativo 30 dias · Sentimos sua falta!',
    );
    expect(winbackCountLabel(0), 'Nenhum envio');
    expect(winbackCountLabel(1), '1 envio');
    expect(winbackCountLabel(4), '4 envios');
    expect(winbackComoCalculamos, contains('30º'));
    expect(winbackComoCalculamos, isNot(contains('7º')));
    expect(winbackHubSubtitle(null), 'Log dos pushes automáticos');
    expect(
      winbackHubSubtitle('Atualizado agora'),
      'Log dos pushes automáticos · Atualizado agora',
    );
    expect(winbackSearchEmptyTitle(''), 'Nenhum envio ainda');
    expect(winbackSearchEmptyTitle('Ana'), 'Nenhum envio encontrado');
    expect(winbackSearchEmptySubtitle('Ana'), contains('nome'));
  });

  test('status de entrega aparece quando o push não chegou', () {
    expect(winbackEntregaFalhaLabel('ENVIADO'), isNull);
    expect(winbackEntregaFalhaLabel(null), isNull);
    expect(winbackEntregaFalhaLabel('SEM_TOKEN'), contains('sem notificações'));
    expect(
      winbackSubtitle(
        tipo: 'ALUNO_INATIVO_60D',
        mensagem: 'Volte!',
        status: 'FALHOU',
      ),
      'Inativo 60 dias · Não entregue: o envio falhou',
    );
    final entry = WinbackLogEntry.fromJson({
      'alunoNome': 'Ana',
      'tipo': 'ALUNO_INATIVO_30D',
      'mensagem': 'x',
      'enviadoEm': '2026-09-01T10:00:00',
      'status': 'SEM_TOKEN',
    });
    expect(entry.status, 'SEM_TOKEN');
  });
}
