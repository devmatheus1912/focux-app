import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/equipe_display.dart';

void main() {
  test('equipeCountLabel e chips', () {
    expect(equipeCountLabel(0), 'Nenhum membro');
    expect(equipeCountLabel(1), '1 membro');
    expect(equipeCountLabel(3), '3 membros');
    expect(equipeChipLabel(EquipeChip.todos), 'Todos');
    expect(equipeChipLabel(EquipeChip.convites), 'Convites');
    expect(equipeChipLabel(EquipeChip.ativos), 'Ativos');
    expect(equipeStatusParam(EquipeChip.todos), isNull);
    expect(equipeStatusParam(EquipeChip.convites), 'CONVIDADO');
    expect(equipeStatusParam(EquipeChip.ativos), 'ATIVO');
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
    expect(
      equipeMembroSubtitle(role: 'SECRETARIA', status: 'CONVIDADO'),
      'Secretaria · Convite enviado',
    );
  });
}
