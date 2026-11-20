import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/fcm/fcm_token_do_aparelho.dart';

void main() {
  late List<String> avisos;
  setUp(() => avisos = []);

  Future<String?> obter({
    required Future<String?> Function() fcm,
    Future<String?> Function()? apns,
    int tentativas = 5,
  }) =>
      obterTokenFcm(
        fcm: fcm,
        apns: apns,
        avisar: avisos.add,
        tentativas: tentativas,
        intervalo: Duration.zero,
      );

  test('iOS: espera o APNs chegar antes de pedir o token', () async {
    var consultas = 0;
    var pediuFcm = false;
    final token = await obter(
      apns: () async => ++consultas < 3 ? null : 'apns',
      fcm: () async {
        pediuFcm = true;
        // Antes do APNs o Firebase lança apns-token-not-set.
        expect(consultas, 3);
        return 'fcm-token';
      },
    );

    expect(token, 'fcm-token');
    expect(pediuFcm, isTrue);
    expect(avisos, isEmpty);
  });

  test('iOS: sem APNs depois das tentativas avisa e não pede o token',
      () async {
    var consultas = 0;
    var pediuFcm = false;
    final token = await obter(
      apns: () async {
        consultas++;
        return null;
      },
      fcm: () async {
        pediuFcm = true;
        return 'x';
      },
    );

    expect(token, isNull);
    expect(consultas, 5);
    expect(pediuFcm, isFalse);
    expect(avisos, ['sem token APNs']);
  });

  test('erro do getToken vira aviso com o motivo, não exceção', () async {
    final token = await obter(
      fcm: () async => throw Exception('FCM Registration failed!'),
    );

    expect(token, isNull);
    expect(avisos.single, contains('FCM Registration failed!'));
  });

  test('Android: pede o token direto e não avisa quando dá certo', () async {
    final token = await obter(fcm: () async => 'fcm-token');

    expect(token, 'fcm-token');
    expect(avisos, isEmpty);
  });

  test('token vazio também avisa', () async {
    expect(await obter(fcm: () async => ''), isNull);
    expect(avisos, ['token FCM vazio']);
  });
}
