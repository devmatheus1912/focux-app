import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_contact_utils.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';

Aluno _aluno({
  int id = 1,
  String status = 'ATIVO',
  bool emRisco = false,
  bool inadimplente = false,
  String statusFinanceiro = 'ATIVO',
  int? diasSemTreino,
  String? proximoContato,
  String? snoozedUntil,
}) {
  return Aluno(
    id: id,
    nome: 'Teste',
    email: 't@test.com',
    status: status,
    statusFinanceiro: statusFinanceiro,
    emRisco: emRisco,
    inadimplente: inadimplente,
    diasSemTreino: diasSemTreino,
    proximoContato: proximoContato,
    snoozedUntil: snoozedUntil,
  );
}

void main() {
  final today = DateTime(2026, 5, 21);

  test('ignora aluno inativo', () {
    expect(
      alunoPrecisaContatoHoje(_aluno(status: 'INATIVO', emRisco: true), now: today),
      isFalse,
    );
  });

  test('respeita snooze da API', () {
    expect(
      alunoPrecisaContatoHoje(
        _aluno(
          emRisco: true,
          snoozedUntil: DateTime(2026, 5, 22, 10).toIso8601String(),
        ),
        now: today,
      ),
      isFalse,
    );
  });

  test('follow-up vencido entra na fila', () {
    expect(
      alunoPrecisaContatoHoje(
        _aluno(proximoContato: '2026-05-20'),
        now: today,
      ),
      isTrue,
    );
  });

  test('dias sem treino usa limite configurável', () {
    expect(
      alunoPrecisaContatoHoje(
        _aluno(diasSemTreino: 6),
        now: today,
        diasSemTreinoLimite: 7,
      ),
      isFalse,
    );
    expect(
      alunoPrecisaContatoHoje(
        _aluno(diasSemTreino: 7),
        now: today,
        diasSemTreinoLimite: 7,
      ),
      isTrue,
    );
  });

  test('boost de prioridade para contato hoje', () {
    expect(
      alunoContatoPriorityBoost(
        _aluno(emRisco: true),
        now: today,
      ),
      greaterThan(0),
    );
  });
}
