import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/widgets/perfil_progresso_bloco.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';

void main() {
  test('peso em destaque compara com a primeira medida', () {
    MedidaCorporal m(String data, double peso) =>
        MedidaCorporal.fromJson({'id': 1, 'data': data, 'peso': peso});
    final serie = serieDaMedida(
      [m('2026-10-31', 88), m('2026-10-30', 90)],
      (x) => x.peso,
    )!;
    expect(serie.atual, 88);
    expect(serie.serie, [90, 88]);
    expect(diferencaDaMedida(serie.atual, serie.inicial), '−2');
    expect(diferencaDaMedida(90, 90), isNull);
    expect(serieDaMedida([], (x) => x.peso), isNull);
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
