import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/gamificacao/utils/gamificacao_display.dart';

void main() {
  test('streak e preview', () {
    expect(gamificacaoStreakLabel(0), '0 dias');
    expect(gamificacaoStreakLabel(1), '1 dia');
    expect(gamificacaoStreakLabel(8), '8 dias');
    expect(gamificacaoStreakLabel(0, isAluno: false), '0 alunos');
    expect(gamificacaoStreakLabel(1, isAluno: false), '1 aluno');
    expect(gamificacaoStreakLabel(3, isAluno: false), '3 alunos');
    expect(gamificacaoStreakTitle(isAluno: false), contains('Alunos'));
    expect(
      gamificacaoStreakHint(isAluno: false, streak: 2, recorde: 10),
      contains('base'),
    );
    expect(gamificacaoBadgePreview([1, 2, 3, 4]), [1, 2, 3]);
    expect(gamificacaoComoGanhar('STREAK_10'), contains('10 dias'));
    expect(
      gamificacaoBadgeSubtitle(earned: true, tipo: 'PR_CARGA', isAluno: false),
      'Na base',
    );
    expect(gamificacaoRotaDoBadge('PR_CARGA', isAluno: true), '/checkin');
    expect(gamificacaoRotaDoBadge('PR_CARGA', isAluno: false), '/alunos');
    expect(gamificacaoPersonalEmptyTitle, contains('base'));
    expect(gamificacaoComoCalculamos, contains('personal'));
    expect(gamificacaoFocusLabel(isAluno: false), 'Ver alunos');
  });
}
