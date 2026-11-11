import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/broadcasts/utils/broadcast_display.dart';

void main() {
  test('broadcastPublicoLabel', () {
    expect(broadcastPublicoLabel(null), 'Todos');
    expect(broadcastPublicoLabel('ONLINE'), 'Online');
    expect(broadcastPublicoLabel('HIBRIDO'), 'Híbrido');
  });

  test('broadcastSendSuccess', () {
    expect(broadcastSendSuccess(0), 'Nenhum aluno no público escolhido.');
    expect(broadcastSendSuccess(1), 'Enviado para 1 aluno.');
    expect(broadcastSendSuccess(4), 'Enviado para 4 alunos.');
    expect(
      broadcastSendSuccess(4, comPush: 4),
      'Enviado para 4 alunos, com notificação no celular.',
    );
    expect(
      broadcastSendSuccess(4, comPush: 1),
      'Enviado para 4 alunos. 1 com notificação; os demais veem ao abrir o app.',
    );
    expect(broadcastSendSuccess(2, comPush: 0), contains('Nenhum tem notificação'));
    expect(broadcastAlunosValue(3, comPush: 2), '3 alunos · 2 com notificação');
    expect(broadcastAlunosValue(3), '3 alunos');
  });

  test('broadcastTipoApi', () {
    expect(broadcastTipoApi('TODOS'), isNull);
    expect(broadcastTipoApi('ONLINE'), 'ONLINE');
  });

  test('broadcastConfirmTitle', () {
    expect(broadcastConfirmTitle('TODOS'), 'Enviar para todos os alunos?');
    expect(broadcastConfirmTitle('TODOS', total: 8), 'Enviar para 8 alunos?');
    expect(broadcastConfirmTitle('PRESENCIAL'), 'Enviar para presencial?');
  });

  test('avisa quem está sem tipo de consultoria', () {
    expect(broadcastSemTipoAviso(const {}), isNull);
    expect(
      broadcastSemTipoAviso(const {'TODOS': 3, 'ONLINE': 3}),
      isNull,
    );
    expect(
      broadcastSemTipoAviso(const {'TODOS': 4, 'ONLINE': 2}),
      contains('2 alunos'),
    );
  });

  test('broadcastEnviosCaption', () {
    expect(broadcastEnviosCaption(0), 'Nenhum envio ainda');
    expect(broadcastEnviosCaption(1), '1 envio');
    expect(broadcastEnviosCaption(3), '3 envios');
  });

  test('broadcastFormatDate', () {
    expect(
      broadcastFormatDate(DateTime(2026, 9, 1, 8, 5)),
      '01/09 · 08:05',
    );
  });

  test('público com 0 alunos fica desligado; Todos sempre liga', () {
    final totais = {'TODOS': 1, 'ONLINE': 1, 'PRESENCIAL': 0, 'HIBRIDO': 0};
    expect(broadcastPublicoHabilitado('PRESENCIAL', totais), isFalse);
    expect(broadcastPublicoHabilitado('ONLINE', totais), isTrue);
    expect(broadcastPublicoHabilitado('TODOS', {'TODOS': 0}), isTrue);
    // Alcance ainda não chegou: não trava a escolha.
    expect(broadcastPublicoHabilitado('HIBRIDO', const {}), isTrue);
  });

  test('todos no mesmo tipo: a escolha some e vira "Vai para N"', () {
    expect(
      broadcastPublicoUnico({'TODOS': 1, 'ONLINE': 1, 'PRESENCIAL': 0}),
      1,
    );
    // Alguém sem tipo: Todos ≠ Online, a escolha continua.
    expect(broadcastPublicoUnico({'TODOS': 3, 'ONLINE': 2}), isNull);
    expect(
      broadcastPublicoUnico({'TODOS': 4, 'ONLINE': 2, 'PRESENCIAL': 2}),
      isNull,
    );
    expect(broadcastVaiPara(1), 'Vai para 1 aluno');
    expect(broadcastVaiPara(3), 'Vai para 3 alunos');
  });
}
