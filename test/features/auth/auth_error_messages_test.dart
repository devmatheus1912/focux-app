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

  test('mapLoginError cobre 401, 400, 502 e rede real', () {
    expect(mapLoginError(dio(401)), 'E-mail ou senha inválidos');
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
      'E-mail ou senha inválidos',
    );
    expect(
      mapLoginError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 400,
            data: {
              'erro': 'Requisição inválida',
              'detalhes': {'senha': 'não deve estar em branco'},
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      ),
      'Dados inválidos. senha: não deve estar em branco',
    );
    expect(
      mapLoginError(dio(400, 'Campo senha é obrigatório')),
      'Campo senha é obrigatório',
    );
    expect(
      mapLoginError(dio(502)),
      'Servidor indisponível, tente novamente',
    );
    expect(
      mapLoginError(dio(503)),
      'Servidor indisponível, tente novamente',
    );
    // badResponse com status nunca vira "sem conexão"
    expect(mapLoginError(dio(401)), isNot(contains('Sem conexão')));
    expect(mapLoginError(dio(400)), isNot(contains('Sem conexão')));
    // Só transporte real
    expect(mapLoginError(dio(null)), 'Sem conexão com o servidor.');
    expect(
      mapLoginError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          type: DioExceptionType.connectionTimeout,
        ),
      ),
      'Sem conexão com o servidor.',
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

  test('mapRegisterAlunoError distingue convite e e-mail duplicado', () {
    expect(
      mapRegisterAlunoError(dio(400, 'Convite inválido ou expirado')),
      contains('Convite inválido'),
    );
    expect(
      mapRegisterAlunoError(dio(409, 'Convite já foi utilizado')),
      contains('já foi utilizado'),
    );
    expect(
      mapRegisterAlunoError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/register/aluno'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/register/aluno'),
            statusCode: 409,
            data: {
              'erro': 'E-mail já cadastrado neste espaço',
              'codigo': 'EMAIL_JA_CADASTRADO_NO_ESPACO',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      ),
      'Este e-mail já está em uso neste espaço.',
    );
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
      'Servidor indisponível, tente novamente',
    );
  });

  test('mapAppleSignInError humaniza 503 / 401 / 400 e nunca 4xx como offline', () {
    expect(
      mapAppleSignInError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/apple'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/apple'),
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        ),
        isAluno: false,
      ),
      contains('ainda não está ativo'),
    );
    expect(
      mapAppleSignInError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/apple'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/apple'),
            statusCode: 401,
            data: {
              'erro': 'Nao foi possivel validar o token Apple.',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
        isAluno: false,
      ),
      'Nao foi possivel validar o token Apple.',
    );
    expect(
      mapAppleSignInError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/apple'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/apple'),
            statusCode: 401,
            data: {'erro': 'Audience Apple invalida'},
          ),
          type: DioExceptionType.badResponse,
        ),
        isAluno: true,
      ),
      'Audience Apple invalida',
    );
    expect(
      mapAppleSignInError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/apple'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/apple'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
        isAluno: false,
      ),
      contains('Apple'),
    );
    expect(
      mapAppleSignInError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/apple'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/apple'),
            statusCode: 400,
          ),
          type: DioExceptionType.badResponse,
        ),
        isAluno: true,
      ),
      contains('e-mail'),
    );
    expect(
      mapAppleSignInError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/apple'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/apple'),
            statusCode: 404,
            data: {'erro': 'Personal não encontrado'},
          ),
          type: DioExceptionType.badResponse,
        ),
        isAluno: true,
      ),
      'Personal não encontrado',
    );
    expect(
      mapAppleSignInError(dio(401), isAluno: false),
      isNot(contains('Sem conexão')),
    );
    expect(
      mapAppleSignInError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/apple'),
          type: DioExceptionType.connectionError,
        ),
        isAluno: false,
      ),
      'Sem conexão com o servidor.',
    );
    expect(
      mapLoginError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          type: DioExceptionType.badCertificate,
        ),
      ),
      contains('conexão segura'),
    );
    expect(
      mapLoginError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          type: DioExceptionType.connectionError,
          error: Exception('Certificate pin mismatch'),
          message: 'Certificate pin mismatch',
        ),
      ),
      contains('conexão segura'),
    );
    // Handshake genérico = rede, não “atualize o app”.
    expect(
      mapLoginError(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          type: DioExceptionType.connectionError,
          error: Exception('HandshakeException: Connection terminated'),
          message: 'The connection errored: HandshakeException',
        ),
      ),
      'Sem conexão com o servidor.',
    );
  });

  test('mapAppleSignInError exige personalSlug para aluno', () {
    expect(
      mapAppleSignInError(
        StateError('PERSONAL_SLUG_REQUIRED'),
        isAluno: true,
      ),
      contains('?p=slug'),
    );
  });

  test('mapMfaVerifyError cobre inválido e expirado', () {
    expect(
      mapMfaVerifyError(dio(400, 'Código inválido.')),
      'Código inválido.',
    );
    expect(mapMfaVerifyError(dio(410)), contains('expirou'));
    expect(
      mapMfaVerifyError(StateError('MFA_STILL_REQUIRED')),
      contains('MFA'),
    );
  });

  test('mapMfaSetupError cobre senha e código', () {
    expect(
      mapMfaSetupError(dio(400, 'Senha incorreta.')),
      'Senha incorreta.',
    );
    expect(
      mapMfaSetupError(dio(401)).toLowerCase(),
      contains('senha'),
    );
  });
}
