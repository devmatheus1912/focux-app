import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/friendly_error.dart';
import 'package:focux_app/core/ux/focux_feedback.dart';

void main() {
  test('uses default fallback for opaque errors', () {
    expect(
      friendlyError(Exception('DioException [bad] internal')),
      FocuxFeedback.defaultFallback,
    );
  });

  test('maps common HTTP status codes to PT-BR messages', () {
    DioException err(int code) => DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: code,
          ),
        );

    expect(friendlyError(err(401)), contains('Sessão'));
    expect(friendlyError(err(403)), contains('permissão'));
    expect(friendlyError(err(404)), contains('encontrado'));
    expect(friendlyError(err(429)), contains('tentativas'));
    expect(friendlyError(err(500)), contains('servidor'));
  });

  test('prefers server message when present', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 400,
        data: {'message': 'Plano já ativo para este aluno.'},
      ),
    );
    expect(friendlyError(err), 'Plano já ativo para este aluno.');
  });

  test('maps timeout to connectivity message', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionTimeout,
    );
    expect(friendlyError(err), contains('internet'));
  });

  group('contexto de mídia e PIX', () {
    DioException err(String path, int code, [Object? data]) => DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: code,
            data: data,
          ),
        );

    test('503 genérico não vira serviço de mídia', () {
      final msg = friendlyError(err('/api/alunos', 503));
      expect(msg, 'Serviço temporariamente indisponível. Tente de novo em instantes.');
      expect(msg, isNot(contains('mídia')));
    });

    test('503 em rota de upload fala de mídia', () {
      expect(friendlyError(err('/api/uploads', 503)), contains('mídia'));
    });

    test('corpo "Service Unavailable" fora de mídia é genérico', () {
      final msg = friendlyError(
        err('/api/treinos', 500, {'erro': 'Service Unavailable'}),
      );
      expect(msg, isNot(contains('mídia')));
      expect(msg, contains('temporariamente indisponível'));
    });

    test('JSON cru fora do PIX não vira erro de PIX', () {
      final msg = friendlyError(
        err('/api/alunos', 500, {'erro': '{"error":"bad_request","cause":[]}'}),
      );
      expect(msg, isNot(contains('PIX')));
      expect(msg, isNot(contains('{')));
    });

    test('JSON cru na rota do PIX vira erro de PIX', () {
      final msg = friendlyError(
        err('/api/financeiro/mensalidades/1/pix', 500, {
          'erro': '{"error":"bad_request","cause":[]}',
        }),
      );
      expect(msg, contains('PIX'));
    });

    test('nenhuma saída expõe infraestrutura', () {
      final saidas = [
        friendlyError(err('/api/uploads', 500, {'erro': 'Cloudinary nao configurado'})),
        friendlyError(err('/api/uploads', 500, {'erro': 'Upload indisponivel no momento'})),
        friendlyError(err('/api/uploads', 500, {'erro': 'Falha no upload de midia'})),
        friendlyError('Cloudinary nao configurado'),
      ];
      for (final msg in saidas) {
        expect(msg, isNot(contains('logs')));
        expect(msg, isNot(contains('CLOUDINARY')));
        expect(msg, isNot(contains('Cloudinary')));
        expect(msg, isNot(contains('_KEY')));
        expect(msg, isNot(contains('backend')));
      }
    });
  });
}
