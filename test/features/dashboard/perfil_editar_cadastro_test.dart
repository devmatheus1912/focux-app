import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/widgets/perfil_progresso_bloco.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';

void main() {
  test('resumo da medida numa linha', () {
    final m = MedidaCorporal.fromJson({'id': 1, 'data': '2026-10-30', 'peso': 90.0, 'cintura': 50.0});
    expect(resumoDaMedida(m), '30/10 · 90 kg · cintura 50 cm');
  });

  test('cadastro só cuida de dados; progresso mora no Perfil', () {
    final tela = File('lib/features/dashboard/screens/perfil_aluno_editar_screen_state.part.dart').readAsStringSync();
    expect(tela, isNot(contains('Progresso corporal')));
    expect(tela, isNot(contains('Últimas atualizações')));
    expect(tela, contains('showDatePicker'));
    expect(tela, contains('_saving || !_isDirty'));
    expect(tela, contains('rotuloFlutuante: true'));
    final hub = File('lib/features/dashboard/widgets/perfil_aluno_hub_body.dart').readAsStringSync();
    expect(hub, contains('PerfilProgressoBloco'));
  });
}
