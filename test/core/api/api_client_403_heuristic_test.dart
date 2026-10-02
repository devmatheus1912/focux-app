import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';

void main() {
  bool derruba(Object? data) => ApiClient.isLikelySessionAuthFailure403(data);

  test('403 com codigo de negócio não derruba a sessão', () {
    expect(derruba({'codigo': 'PLANO_FEATURE_BLOQUEADA', 'mensagem': 'Seu token de IA acabou'}), isFalse);
    expect(derruba({'codigo': 'SENHA_PROVISORIA_PENDENTE'}), isFalse);
    expect(derruba({'codigo': 'ALUNO_BLOQUEADO'}), isFalse);
  });

  test('mensagem com palavra solta não derruba', () {
    expect(derruba({'mensagem': 'Assinatura expirada. Renove para continuar.'}), isFalse);
    expect(derruba({'mensagem': 'Acesso negado para este recurso'}), isFalse);
  });

  test('upload ganha 5 min de envio e não entra no retry', () {
    final o = RequestOptions(path: '/api/uploads', sendTimeout: const Duration(seconds: 30));
    ApiClient.applyUploadPolicy(o);
    expect(o.sendTimeout, const Duration(minutes: 5));
    expect(o.receiveTimeout, const Duration(minutes: 2));
    expect(o.extra['fxNoRetry'], isTrue);
  });

  test('403 vazio ou de JWT derruba', () {
    expect(derruba(null), isTrue);
    expect(derruba(''), isTrue);
    expect(derruba({'error': 'Full authentication is required'}), isTrue);
    expect(derruba('JWT expired'), isTrue);
  });
}
