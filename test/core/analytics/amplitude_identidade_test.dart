import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/analytics/analytics_service.dart';
import 'package:focux_app/core/auth/jwt_session_identity.dart';

String _jwt(Map<String, Object?> payload) {
  String parte(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${parte({'alg': 'HS256'})}.${parte(payload)}.assinatura';
}

void main() {
  test('o id do Amplitude é o sub do token, sem nome nem e-mail', () {
    expect(
      JwtSessionIdentity.subject(_jwt({'sub': 'personal:12', 'personal_id': 12})),
      'personal:12',
    );
    expect(JwtSessionIdentity.subject(_jwt({'sub': 'aluno:34'})), 'aluno:34');
    expect(JwtSessionIdentity.subject('lixo'), isNull);
    expect(JwtSessionIdentity.subject(_jwt({'role': 'ALUNO'})), isNull);
  });

  test('trocar de conta troca o usuário; sair esquece', () async {
    final a = AnalyticsService.instance;
    await a.setUser(id: 'personal:12', role: 'personal');
    expect(a.usuarioAtual, 'personal:12');
    await a.setUser(id: 'aluno:34', role: 'aluno');
    expect(a.usuarioAtual, 'aluno:34');
    await a.esquecerUsuario();
    expect(a.usuarioAtual, isNull);
  });

  test('login e logout passam pelo analytics (auth_provider)', () {
    final src = File('lib/features/auth/providers/auth_provider.dart').readAsStringSync();
    expect(src, contains('listenSelf('));
    expect(src, contains('AnalyticsService.instance.setUser('));
    expect(src, contains('AnalyticsService.instance.esquecerUsuario()'));
  });

  test('os três jeitos de terminar o treino mandam treino_concluido', () {
    expect(ProductEvents.treinoConcluido, 'treino_concluido');
    expect(
      File('lib/features/checkin/utils/checkin_sessao.dart').readAsStringSync(),
      contains("checkinTreinoConcluido(modo: 'registrado')"),
    );
    for (final p in [
      'lib/features/checkin/screens/checkin_screen_saida.part.dart',
      'lib/features/checkin/screens/treino_previa_screen.dart',
    ]) {
      expect(File(p).readAsStringSync(), contains("checkinTreinoConcluido(modo: 'ja_fiz')"), reason: p);
    }
  });
}
