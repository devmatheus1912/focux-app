import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/admin/models/permissao_rbac.dart';

void main() {
  test('PermissaoRbac parses backend payload', () {
    final p = PermissaoRbac.fromJson({
      'id': 1,
      'personalId': 42,
      'recurso': 'FINANCEIRO',
      'nivel': 'WRITE',
    });
    expect(p.recurso, 'FINANCEIRO');
    expect(p.nivel, 'WRITE');
  });

  test('RbacRepository aligns with backend RBAC API', () {
    final source = File(
      'lib/features/admin/data/rbac_repository.dart',
    ).readAsStringSync();
    expect(source, contains("'/api/rbac/permissoes'"));
    expect(source, contains('.put('));
    expect(source, contains(".delete('/api/rbac/permissoes/"));
    expect(source, isNot(contains('usuarioConvidadoId')));
  });

  test('TrilhasRepository concluirMarco uses POST with trilhaId', () {
    final source = File(
      'lib/features/trilhas/data/trilhas_repository.dart',
    ).readAsStringSync();
    expect(
      source,
      contains("'/api/trilhas/\$trilhaId/marcos/\$marcoId/concluir'"),
    );
    expect(source, contains("'/api/trilhas/\$trilhaId/progresso'"));
    expect(source, contains("'/api/trilhas/minhas'"));
    expect(source, contains("'/api/trilhas/\$trilhaId'"));
    expect(source, contains('.post('));
    expect(source, contains('.put('));
    expect(source, contains('.delete('));
    expect(source, isNot(contains('.patch(')));
  });
}
