import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
