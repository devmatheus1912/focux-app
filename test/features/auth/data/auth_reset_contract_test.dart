import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reset de senha no app só pede OTP de personal', () {
    final repo =
        File('lib/features/auth/data/auth_repository.dart').readAsStringSync();
    expect(repo, isNot(contains("'tipo': isAluno ? 'ALUNO' : 'PERSONAL'")));
    expect(repo, contains("'tipo': 'PERSONAL'"));
  });
}
