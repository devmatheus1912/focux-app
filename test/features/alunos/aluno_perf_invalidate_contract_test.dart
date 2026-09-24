import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('follow-up não limpa cache 360 de toda a carteira', () {
    final src = File(
      'lib/features/alunos/providers/aluno_followup_provider.dart',
    ).readAsStringSync();
    expect(src, contains('invalidateAlunosListCachesRef'));
    expect(src, contains('Aluno360ClientCache.invalidate(alunoId)'));
    expect(src, isNot(contains('invalidateAlunosCachesRef')));
    expect(src, isNot(contains('Aluno360ClientCache.clear()')));
  });

  test('warm 360 limita a 3 alunos', () {
    final src = File(
      'lib/features/alunos/providers/aluno_detail_providers.dart',
    ).readAsStringSync();
    expect(src, contains('alunoIds.take(3)'));
    expect(src, isNot(contains('alunoIds.take(8)')));
    expect(src, contains('StateProvider.autoDispose.family'));
  });
}
