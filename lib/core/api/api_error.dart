import 'package:dio/dio.dart';

/// Corpo de erro padrão do backend (`ApiErrorResponse`), conforme §2 do
/// contrato pareado em `docs/CONTRATO_APP_BACKEND.md`.
///
/// O campo da mensagem chama `erro` — não `mensagem`. E `codigo`, `detalhes` e
/// `upgradePlano` chegam sob `@JsonInclude(NON_NULL)` no servidor, então
/// ausência é o caso normal em endpoint que ainda não popula o código, não
/// anomalia a ser tratada como erro de parse.
class ApiError {
  /// Texto do campo `erro`. Continua sendo a única coisa exibível enquanto o
  /// catálogo de códigos não cobre todos os pontos de lançamento.
  final String? mensagem;
  final int? status;
  final String? requestId;

  /// Classificação estável. Quando presente, é a fonte da verdade — o texto
  /// de [mensagem] não deve ser consultado para decidir comportamento.
  final String? codigo;

  /// Tier a oferecer no upgrade (`PRO`, `ENTERPRISE`). Existe para a sheet de
  /// upgrade não precisar inferir o plano a partir do texto do erro.
  final String? upgradePlano;

  final Map<String, String> detalhes;

  const ApiError({
    this.mensagem,
    this.status,
    this.requestId,
    this.codigo,
    this.upgradePlano,
    this.detalhes = const {},
  });

  /// Qual recurso o gate bloqueou, quando o código é
  /// `PLANO_FEATURE_REQUER_UPGRADE`. Uma feature por código seria um catálogo
  /// crescendo a cada recurso novo; o backend manda o nome aqui.
  String? get feature => detalhes['feature'];

  /// Teto do plano no momento do erro, para os códigos de cota.
  String? get limite => detalhes['limite'];

  bool get hasCodigo => codigo != null && codigo!.isNotEmpty;

  /// `null` quando não houve corpo de erro do backend: falha de transporte,
  /// timeout, HTML de proxy. Nesses casos não há classificação a fazer.
  static ApiError? from(Object error) {
    if (error is! DioException) return null;
    final response = error.response;
    if (response == null) return null;
    final data = response.data;

    if (data is String) {
      final text = data.trim();
      return ApiError(
        mensagem: text.isEmpty ? null : text,
        status: response.statusCode,
      );
    }
    if (data is! Map) {
      return ApiError(status: response.statusCode);
    }

    return ApiError(
      // `erro` primeiro: é o nome real do campo no contrato. Os outros ficam
      // como tolerância a endpoint legado.
      mensagem: _string(
        data['erro'] ?? data['message'] ?? data['mensagem'] ?? data['error'],
      ),
      status: _int(data['status']) ?? response.statusCode,
      requestId: _string(data['requestId']),
      codigo: _string(data['codigo']),
      upgradePlano: _string(data['upgradePlano']),
      detalhes: _stringMap(data['detalhes']),
    );
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    final result = <String, String>{};
    value.forEach((key, entry) {
      if (entry == null) return;
      result[key.toString()] = entry.toString();
    });
    return result;
  }
}

/// Catálogo de códigos acordado em §2.3 do contrato pareado.
///
/// Agrupado por como o app reage, não por status HTTP: é a reação que decide
/// se a tela abre sheet de upgrade, avisa de limite, ou trata como falha.
abstract final class ApiErrorCodes {
  /// O recurso existe, mas o tier atual não alcança. Upgrade resolve.
  static const planGate = <String>{
    'PLANO_FEATURE_REQUER_UPGRADE',
    'PLANO_IMPORTACAO_FOTO_REQUER_UPGRADE',
    'IA_PLANO_INSUFICIENTE',
  };

  /// O tier alcança, mas o teto do período foi atingido.
  static const quotaExceeded = <String>{
    'IA_QUOTA_ESGOTADA',
    'PLANO_LIMITE_ALUNOS_ATINGIDO',
    'PLANO_LIMITE_ASSISTENTES_ATINGIDO',
    'MIGRACAO_FOTO_QUOTA_ESGOTADA',
  };

  /// Conflito por recurso já existente — o usuário precisa mudar o dado, não
  /// tentar de novo.
  static const alreadyExists = <String>{
    'ALUNO_EMAIL_JA_EXISTE',
    'EMAIL_JA_CADASTRADO',
    'EMAIL_JA_CADASTRADO_NO_ESPACO',
  };

  /// Excesso de tentativas na janela de uma hora.
  static const rateLimited = <String>{
    'CODIGO_EMAIL_LIMITE_HORA',
    'CODIGO_SENHA_LIMITE_HORA',
  };

  /// Login recusado — e-mail ou senha. Não é gate de plano.
  static const credentials = <String>{
    'CREDENCIAIS_INVALIDAS',
  };

  /// Senha provisória / atual recusada na troca obrigatória.
  static const passwordChallenge = <String>{
    'SENHA_ATUAL_INVALIDA',
  };

  /// Se o código está no catálogo que este app conhece.
  ///
  /// Existe para separar "código conhecido que não é gate" — decisão fechada —
  /// de "código que o backend passou a mandar depois desta versão". No segundo
  /// caso o app não pode concluir nada pelo código, e cai no heurístico de
  /// texto, senão um código novo derrubaria a detecção em silêncio.
  static bool isKnown(String codigo) =>
      planGate.contains(codigo) ||
      quotaExceeded.contains(codigo) ||
      alreadyExists.contains(codigo) ||
      rateLimited.contains(codigo) ||
      credentials.contains(codigo) ||
      passwordChallenge.contains(codigo);
}
