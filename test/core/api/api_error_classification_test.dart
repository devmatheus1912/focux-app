import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_error.dart';
import 'package:focux_app/core/utils/friendly_error.dart';

DioException _dio({
  int status = 403,
  Object? data,
}) {
  final options = RequestOptions(path: '/api/teste');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  test('le erro, codigo, upgradePlano e detalhes.feature', () {
    final parsed = ApiError.from(
      _dio(
        data: {
          'erro':
              'O recurso POSE_COACH requer plano ENTERPRISE ou superior. Faca upgrade.',
          'status': 403,
          'requestId': 'a1b2c3',
          'codigo': 'PLANO_FEATURE_REQUER_UPGRADE',
          'upgradePlano': 'ENTERPRISE',
          'detalhes': {'feature': 'POSE_COACH'},
        },
      ),
    );

    expect(parsed, isNotNull);
    expect(parsed!.codigo, 'PLANO_FEATURE_REQUER_UPGRADE');
    expect(parsed.upgradePlano, 'ENTERPRISE');
    expect(parsed.feature, 'POSE_COACH');
    expect(parsed.mensagem, contains('POSE_COACH'));
    expect(isPlanGateError(_dio(data: {
      'erro': parsed.mensagem,
      'codigo': parsed.codigo,
    })), isTrue);
  });

  test('codigo de gate decide sozinho, mesmo com texto que nao parece gate', () {
    final error = _dio(
      data: {
        'erro': 'Recurso indisponivel nesta assinatura.',
        'codigo': 'PLANO_FEATURE_REQUER_UPGRADE',
      },
    );

    expect(isPlanGateError(error), isTrue);
    expect(isPlanQuotaError(error), isFalse);
    expect(isPlanRestrictionError(error), isTrue);
  });

  test('codigo de cota nao e gate, mesmo com Faca upgrade no texto', () {
    // O heuristico antigo classificaria isto como gate. Cota e teto atingido,
    // nao tier insuficiente — misturar os dois abre a sheet de upgrade errada.
    final error = _dio(
      data: {
        'erro':
            'Cota mensal de IA esgotada (120 requisicoes/mes). Faca upgrade para ENTERPRISE.',
        'codigo': 'IA_QUOTA_ESGOTADA',
        'upgradePlano': 'ENTERPRISE',
        'detalhes': {'limite': '120'},
      },
    );

    expect(isPlanGateError(error), isFalse);
    expect(isPlanQuotaError(error), isTrue);
    expect(isPlanRestrictionError(error), isTrue);
    expect(ApiError.from(error)!.limite, '120');
  });

  test('codigo conhecido que nao e entitlement nao cai no heuristico de texto',
      () {
    final error = _dio(
      status: 409,
      data: {
        'erro': 'Este e-mail ja requer plano PRO. Faca upgrade.',
        'codigo': 'EMAIL_JA_CADASTRADO',
      },
    );

    expect(isPlanGateError(error), isFalse);
    expect(isPlanQuotaError(error), isFalse);
    expect(isPlanRestrictionError(error), isFalse);
  });

  test('codigo fora do catalogo cai no heuristico de texto', () {
    // Codigo que o backend passou a mandar depois desta versao nao pode
    // virar "nao e gate" e derrubar a sheet em silencio.
    final error = _dio(
      data: {
        'erro': 'O recurso X requer plano PRO. Faca upgrade.',
        'codigo': 'PLANO_FEATURE_NOVA_QUE_O_APP_AINDA_NAO_CONHECE',
      },
    );

    expect(ApiErrorCodes.isKnown('PLANO_FEATURE_NOVA_QUE_O_APP_AINDA_NAO_CONHECE'),
        isFalse);
    expect(isPlanGateError(error), isTrue);
  });

  test('sem codigo, 403 com texto de gate continua sendo gate', () {
    final error = _dio(
      data: {
        'erro':
            'O recurso POSE_COACH requer plano ENTERPRISE ou superior. Faca upgrade.',
      },
    );

    expect(isPlanGateError(error), isTrue);
    expect(isPlanQuotaError(error), isFalse);
  });

  test('sem codigo, 403 sem texto de gate nao e gate', () {
    final error = _dio(data: {'erro': 'Sem permissao para este recurso.'});

    expect(isPlanGateError(error), isFalse);
    expect(isPlanRestrictionError(error), isFalse);
  });

  test('campo da mensagem e erro, nao mensagem', () {
    final parsed = ApiError.from(
      _dio(
        status: 400,
        data: {
          'erro': 'do contrato',
          'mensagem': 'legado',
          'message': 'ingles',
        },
      ),
    );

    expect(parsed!.mensagem, 'do contrato');
  });

  test('ausencia de codigo nao e anomalia de parse', () {
    final parsed = ApiError.from(_dio(status: 500, data: {'erro': 'falhou'}));

    expect(parsed!.hasCodigo, isFalse);
    expect(parsed.detalhes, isEmpty);
    expect(parsed.upgradePlano, isNull);
  });

  test('friendlyError prefere o campo erro', () {
    final error = _dio(
      status: 400,
      data: {
        'erro': 'Plano ja ativo para este aluno.',
        'message': 'nao deve aparecer',
      },
    );

    expect(friendlyError(error), 'Plano ja ativo para este aluno.');
  });
}
