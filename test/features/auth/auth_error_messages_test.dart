import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/auth_error_messages.dart';

void main() {
  DioException dio(int? status, [String? message]) {
    return DioException(
      requestOptions: RequestOptions(path: '/api/auth/register/personal'),
      response:
          status == null
              ? null
              : Response(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: status,
                data: message == null ? null : {'message': message},
              ),
      type:
          status == null
              ? DioExceptionType.connectionError
              : DioExceptionType.badResponse,
    );
  }

  test('mapRegisterError prioriza message do backend', () {
    expect(
      mapRegisterError(dio(400, 'Código inválido. Confira e tente de novo.')),
      'Código inválido. Confira e tente de novo.',
    );
    expect(mapRegisterError(dio(409)), 'Este e-mail já está em uso.');
    expect(
      mapRegisterError(dio(429, 'Muitas tentativas. Solicite um novo código.')),
      'Muitas tentativas. Solicite um novo código.',
    );
  });

  test('mapSignupCodeError cobre SMTP e cooldown', () {
    expect(
      mapSignupCodeError(
        dio(400, 'Envio de e-mail indisponível no momento. Tente mais tarde ou cadastre com Google.'),
      ),
      contains('indisponível'),
    );
    expect(mapSignupCodeError(dio(429)), contains('Aguarde'));
  });

  test('mapLoginError cobre 401 e rate limit', () {
    expect(mapLoginError(dio(401)), contains('Email ou senha'));
    expect(mapLoginError(dio(429)), contains('Muitas tentativas'));
    expect(
      mapLoginError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 401,
            data: {
              'erro': 'Credenciais inválidas',
              'codigo': 'CREDENCIAIS_INVALIDAS',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      ),
      contains('Email ou senha'),
    );
    expect(mapEsqueciSenhaError(dio(null)), 'Sem conexão com o servidor.');
    expect(mapEsqueciSenhaError(dio(429)), contains('Muitas tentativas'));
    expect(mapResetCodigoError(dio(429)), contains('novo código'));
    expect(mapResetCodigoError(dio(400, 'Código inválido. Confira e tente de novo.')), contains('Código inválido'));
    expect(mapResetSenhaError(dio(null)), 'Sem conexão com o servidor.');
    expect(mapResetSenhaError(dio(400)), contains('senha'));
    expect(mapDefinirSenhaError(dio(null)), 'Sem conexão com o servidor.');
    expect(mapDefinirSenhaError(dio(401)), contains('provisória'));
    expect(
      mapDefinirSenhaError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/aluno/definir-senha'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/aluno/definir-senha'),
            statusCode: 401,
            data: {
              'erro': 'Senha atual inválida',
              'codigo': 'SENHA_ATUAL_INVALIDA',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      ),
      contains('provisória'),
    );
    expect(mapDefinirSenhaError(dio(400)), contains('8 caracteres'));
  });

  test('mapGoogleSignInError humaniza timeout do proxy', () {
    expect(
      mapGoogleSignInError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/google'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/google'),
            statusCode: 502,
            data: 'Application failed to respond',
          ),
          type: DioExceptionType.badResponse,
        ),
        isAluno: false,
      ),
      'Servidor indisponível no momento. Tente de novo em instantes.',
    );
  });
}
