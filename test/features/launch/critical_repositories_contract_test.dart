import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/config/env.dart';

void main() {
  test('critical repositories call expected API paths', () {
    final checks = {
      'lib/features/auth/data/auth_repository.dart': '/api/auth/login',
      'lib/features/alunos/data/aluno_repository.dart': '/api/alunos',
      'lib/features/treinos/data/treino_repository.dart': '/api/treinos',
      'lib/features/checkin/data/checkin_repository.dart': '/api/checkin',
      'lib/features/chat/data/chat_repository.dart': '/api/chat',
      'lib/features/convites/data/convite_repository.dart': '/api/convites',
      'lib/features/captura/data/captura_repository.dart': '/api/captura',
      'lib/features/financeiro/data/financeiro_repository.dart':
          '/api/financeiro',
      'lib/features/suporte/data/suporte_repository.dart': '/api/suporte',
      'lib/features/onboarding/data/onboarding_repository.dart':
          '/api/onboarding/status',
      'lib/features/notificacoes/data/notificacoes_repository.dart':
          '/api/notificacoes',
      'lib/features/planos/data/planos_repository.dart': '/api/planos/me',
      'lib/features/perfil/data/white_label_repository.dart':
          '/api/personal/white-label',
    };

    for (final entry in checks.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(source, contains(entry.value));
    }
  });

  test('public URLs use configurable base (Railway default)', () {
    expect(Env.capturaPageUrl('demo'), contains('/c/demo'));
    expect(Env.landingPageUrl('demo'), contains('/p/demo'));
    expect(Env.isProd, isTrue);
  });
}
