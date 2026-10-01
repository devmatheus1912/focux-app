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
    expect(coachPendingChipLabel(1), '1 aluno pede atenção');
    expect(coachPendingChipLabel(3), '3 alunos pedem atenção');
    expect(coachPendingTitulo(2), '2 alunos precisam de atenção');
    expect(coachEmptyTitle, contains('atenção'));
    expect(coachEmptySubtitle, contains('check-in'));
    expect(coachComoCalculamos, contains('push'));
    expect(coachComoResolver, contains('volta a treinar'));
  });

  test('motivo vem do backend e cai no tipo quando falta', () {
    const comMotivo = CoachHomeItem(
      id: 1,
      alunoId: 9,
      alunoNome: 'Ana',
      tipo: 'SEM_TREINO_5D',
      mensagem: 'Oi! Notei que faz alguns dias sem treinar.',
      rota: '/alunos/9',
      lido: false,
      criadoEm: '',
      motivo: '9 dias sem treinar',
      alertas: 2,
    );
    expect(coachMotivo(comMotivo), '9 dias sem treinar');
    expect(coachJaAvisado(comMotivo), startsWith('Já avisamos o aluno:'));

    const semMotivo = CoachHomeItem(
      id: 2,
      alunoId: 4,
      alunoNome: 'Bia',
      tipo: 'SONO_BAIXO',
      mensagem: '',
      rota: '',
      lido: false,
      criadoEm: '',
    );
    expect(coachMotivo(semMotivo), 'Dormiu menos de 5h');
    expect(coachJaAvisado(semMotivo), isNull);
  });

  test('json do item traz motivo e alertas', () {
    final item = CoachHomeItem.fromJson({
      'id': 3,
      'alunoId': 7,
      'alunoNome': 'Caio',
      'tipo': 'STREAK_QUEBRADO',
      'mensagem': 'Sua sequência parou',
      'rota': '/alunos/7',
      'lido': false,
      'criadoEm': '2026-09-30T08:00:00',
      'motivo': 'Parou de treinar nesta semana',
      'alertas': 3,
    });
    expect(item.motivo, 'Parou de treinar nesta semana');
    expect(item.alertas, 3);
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
