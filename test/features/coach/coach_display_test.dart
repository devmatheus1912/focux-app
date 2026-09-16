import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/coach/data/coach_proativo_repository.dart';
import 'package:focux_app/features/coach/utils/coach_display.dart';

void main() {
  test('rota do home cai no aluno', () {
    const item = CoachHomeItem(
      id: 1,
      alunoId: 9,
      alunoNome: 'Ana',
      tipo: 'SEM_TREINO_5D',
      mensagem: 'Volta',
      rota: '/alunos/9',
      lido: false,
      criadoEm: '',
    );
    expect(coachRota(item), '/alunos/9');
    expect(
      coachRota(
        const CoachHomeItem(
          id: 2,
          alunoId: 4,
          alunoNome: 'Bia',
          tipo: 'SONO_BAIXO',
          mensagem: 'Durma',
          rota: '',
          lido: false,
          criadoEm: '',
        ),
      ),
      '/alunos/4',
    );
    expect(coachChatRota(item), '/alunos/9/chat');
    expect(coachAgendaRota(item), '/agenda');
    expect(coachPedeAgenda('SONO_BAIXO'), isFalse);
    expect(coachPendingChipLabel(0), isNull);
    expect(coachPendingChipLabel(1), '1 recado do coach');
    expect(coachPendingChipLabel(3), '3 recados do coach');
    expect(coachEmptyTitle, contains('coach'));
    expect(coachEmptySubtitle, contains('check-in'));
    expect(coachComoCalculamos, contains('catálogo'));
  });

  test('coachFocusActions keeps open as P0 and secondary under demand', () {
    final full = coachFocusActions(canChat: true, canAgenda: true);
    expect(full.primary, CoachFocusActionId.open);
    expect(full.secondary, [
      CoachFocusActionId.chat,
      CoachFocusActionId.agenda,
      CoachFocusActionId.ack,
    ]);
    final lean = coachFocusActions(canChat: false, canAgenda: false);
    expect(lean.secondary, [CoachFocusActionId.ack]);
    expect(coachFocusActionLabel(CoachFocusActionId.open), 'Abrir aluno');
  });
}
