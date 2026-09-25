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
    expect(broadcastConfirmTitle('TODOS'), 'Enviar para toda a base?');
    expect(broadcastConfirmTitle('PRESENCIAL'), 'Enviar para presencial?');
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
}
