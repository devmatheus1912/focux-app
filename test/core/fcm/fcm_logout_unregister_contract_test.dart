import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final fcm = File('lib/core/fcm/fcm_service.dart').readAsStringSync();
  final tapRoute = File('lib/core/fcm/fcm_tap_route.dart').readAsStringSync();
  final authRepo =
      File('lib/features/auth/data/auth_repository.dart').readAsStringSync();

  test('logout desregistra o token antes de revogar a sessao', () {
    // A ordem e o contrato: o endpoint exige sessao, e o SessionInvalidator
    // roda depois com o storage ja limpo. Chamar do lugar errado transforma
    // o fix em no-op silencioso.
    final desregistra = authRepo.indexOf('FcmService.desregistrarToken');
    final revoga = authRepo.indexOf("'/api/auth/logout'");

    expect(desregistra, greaterThanOrEqualTo(0));
    expect(revoga, greaterThanOrEqualTo(0));
    expect(desregistra, lessThan(revoga));
  });

  test('desregistrarToken chama o DELETE e derruba o token local', () {
    expect(fcm, matches(RegExp(r"dio\.delete\(\s*'/api/fcm/token'")));
    // Sem o deleteToken local o aparelho segue recebendo push da sessao
    // anterior quando a chamada ao servidor falha.
    expect(fcm, contains('messaging.deleteToken()'));
  });

  test('desregistrarToken nao deixa excecao escapar para o logout', () {
    final inicio = fcm.indexOf('static Future<void> desregistrarToken');
    expect(inicio, greaterThanOrEqualTo(0));
    final corpo = fcm.substring(inicio);

    // FirebaseMessaging.instance lanca quando o Firebase nao foi
    // inicializado (web, ou falha do initializeApp), e logout precisa
    // concluir de qualquer forma.
    final instancia = corpo.indexOf('FirebaseMessaging.instance');
    final tryExterno = corpo.indexOf('try {');
    expect(tryExterno, greaterThanOrEqualTo(0));
    expect(tryExterno, lessThan(instancia));
  });

  test('pos-login reclama o token FCM com JWT', () {
    expect(fcm, contains('registrarSeAutenticado'));
    expect(authRepo, contains('FcmService.registrarSeAutenticado'));
  });

  test('tap com execucaoId abre o detalhe do historico do aluno', () {
    expect(fcm, contains('resolveFcmTapRoute'));
    expect(tapRoute, contains("data['execucaoId']"));
    expect(tapRoute, contains("'/checkin/historico/\$execucaoId'"));
  });

  test('DELETE de logout nao invalida sessao nem entra na fila offline', () {
    expect(fcm, contains("'fxNoInvalidate': true"));
    expect(fcm, contains("'fxNoOfflineQueue': true"));
  });
}
