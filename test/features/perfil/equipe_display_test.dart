import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/equipe_display.dart';

void main() {
  test('equipeHubSubtitle junta freshness', () {
    expect(equipeHubSubtitle(null), 'Assistentes e permissões');
    expect(
      equipeHubSubtitle('há 1 min'),
      'Assistentes e permissões · há 1 min',
    );
  });

  test('equipeRoleLabel cobre papéis do tenant', () {
    expect(equipeRoleLabel('OWNER'), 'Dono');
    expect(equipeRoleLabel('CO_PERSONAL'), 'Co-personal');
    expect(equipeRoleLabel('SECRETARIA'), 'Secretaria');
    expect(equipeRoleLabel('ESTAGIARIO'), 'Estagiário');
    expect(equipeRoleLabel('SUPORTE'), 'Suporte');
    expect(equipeRoleLabel('ASSISTENTE'), 'Assistente');
    expect(equipeRoleLabel(''), 'Sem papel');
    expect(equipeRoleLabel(null), 'Sem papel');
  });

  test('equipeStatusLabel e subtitle', () {
    expect(equipeStatusLabel('ATIVO'), 'Ativo');
    expect(equipeStatusLabel('CONVIDADO'), 'Convite enviado');
    expect(equipeStatusLabel('SUSPENSO'), 'Suspenso');
    expect(equipeMembroSubtitle(role: 'SECRETARIA', status: 'CONVIDADO'),
        'Secretaria · Convite enviado');
  });
}
