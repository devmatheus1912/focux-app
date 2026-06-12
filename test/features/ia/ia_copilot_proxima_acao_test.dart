import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/ia_copilot_proxima_acao.dart';

void main() {
  test('fromJson prefers acao and falls back to titulo or mensagem', () {
    final acao = IaCopilotProximaAcao.fromJson({
      'acao': 'Ligar para aluno',
      'motivo': 'Sem check-in',
      'status': 'ABERTO',
    });
    expect(acao.displayText, 'Ligar para aluno');
    expect(acao.statusLabel, 'ABERTO');
    expect(acao.hasPersistedActionKey, isFalse);

    final fallback = IaCopilotProximaAcao.fromJson({
      'titulo': 'Revisar plano',
      'mensagem': 'Ignorada quando titulo existe',
    });
    expect(fallback.displayText, 'Revisar plano');
    expect(fallback.statusLabel, 'ABERTO');
  });

  test('actionKey signals persisted task', () {
    final saved = IaCopilotProximaAcao.fromJson({
      'acao': 'Enviar mensagem',
      'actionKey': 'CC_123',
    });
    expect(saved.hasPersistedActionKey, isTrue);
  });
}
