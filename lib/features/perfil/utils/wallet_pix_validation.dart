import 'package:flutter/services.dart';

import '../../../core/utils/br_phone.dart';

/// Validação e hints para chaves PIX na carteira do personal.
class WalletPixValidation {
  WalletPixValidation._();

  static String labelForTipo(String tipo) {
    return switch (tipo) {
      'CPF' => 'CPF',
      'CNPJ' => 'CNPJ',
      'EMAIL' => 'E-mail',
      'TELEFONE' => 'Telefone',
      'ALEATORIA' => 'Chave aleatória',
      _ => tipo,
    };
  }

  static String hintForTipo(String? tipo) {
    return switch (tipo) {
      'CPF' => '000.000.000-00',
      'CNPJ' => '00.000.000/0000-00',
      'EMAIL' => 'seu@email.com',
      'TELEFONE' => '(11) 99999-9999',
      'ALEATORIA' => 'UUID gerada pelo banco',
      _ => 'Informe a chave conforme o tipo selecionado',
    };
  }

  static TextInputType keyboardForTipo(String? tipo) {
    return switch (tipo) {
      'CPF' || 'CNPJ' || 'TELEFONE' => TextInputType.number,
      'EMAIL' => TextInputType.emailAddress,
      _ => TextInputType.text,
    };
  }

  static List<TextInputFormatter> formattersForTipo(String? tipo) {
    return switch (tipo) {
      'CPF' => [_CpfInputFormatter()],
      'CNPJ' => [_CnpjInputFormatter()],
      'TELEFONE' => [BrPhone.formatter()],
      _ => const [],
    };
  }

  static String normalizeForApi(String? tipo, String value) {
    final trimmed = value.trim();
    return switch (tipo) {
      'CPF' || 'CNPJ' || 'TELEFONE' => trimmed.replaceAll(RegExp(r'\D'), ''),
      _ => trimmed,
    };
  }

  /// Formata valor vindo da API para exibição mascarada no campo.
  static String formatDisplay(String? tipo, String raw) {
    if (raw.trim().isEmpty) return raw;

    final formatter = switch (tipo) {
      'CPF' => _CpfInputFormatter(),
      'CNPJ' => _CnpjInputFormatter(),
      'TELEFONE' => BrPhone.formatter(),
      _ => null,
    };
    if (formatter == null) return raw.trim();

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return raw.trim();

    return formatter
        .formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: digits),
        )
        .text;
  }

  static String? validateTipo(String? tipo) {
    if (tipo == null || tipo.isEmpty) {
      return 'Selecione o tipo de chave PIX';
    }
    return null;
  }

  static String? validateChave(String? tipo, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Informe a chave PIX';

    return switch (tipo) {
      'CPF' => _validateCpf(trimmed),
      'CNPJ' => _validateCnpj(trimmed),
      'EMAIL' => _validateEmail(trimmed),
      'TELEFONE' => _validatePhone(trimmed),
      'ALEATORIA' => _validateAleatoria(trimmed),
      _ => 'Selecione o tipo de chave antes de informar o valor',
    };
  }

  static String? _validateCpf(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'CPF deve ter 11 dígitos';
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return 'CPF inválido';
    }
    return null;
  }

  static String? _validateCnpj(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return 'CNPJ deve ter 14 dígitos';
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) {
      return 'CNPJ inválido';
    }
    return null;
  }

  static String? _validateEmail(String value) {
    final ok = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value);
    return ok ? null : 'Informe um e-mail válido';
  }

  static String? _validatePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    return null;
  }

  static String? _validateAleatoria(String value) {
    if (value.length < 32) {
      return 'Chave aleatória deve ter ao menos 32 caracteres';
    }
    return null;
  }
}

const walletChavePixMax = 120;

String walletSalvarTileLabel() => 'Salvar chave';

String walletTrocarConfirmTitle() => 'Trocar a chave PIX?';

/// O valor novo, mascarado: quem confirma vê para onde o dinheiro vai.
String walletTrocarConfirmMessage(String rotuloMascarado) =>
    'Os próximos pagamentos dos alunos vão para: $rotuloMascarado. '
    'Cobranças já enviadas continuam com a chave antiga.';

String walletTrocarConfirmLabel() => 'Trocar chave';

String walletTrocarMotivoAparelho() => 'Confirme para trocar a chave PIX';

String walletDiscardTitle() => 'Descartar alterações?';

String walletDiscardMessage() =>
    'Você alterou a chave PIX. Se sair agora, a mudança não será salva.';

String walletCopiarTileLabel() => 'Copiar chave';

String walletChaveCopiada() =>
    'Chave copiada. Cole para o aluno que vai pagar por fora.';

String walletParaQueServe() =>
    'É a chave que aparece nas cobranças de mensalidade, loja e recorrência.';

/// "CPF · ***.615.761-**".
String walletRotuloMascarado(String? tipo, String chave) =>
    '${WalletPixValidation.labelForTipo(tipo ?? '')} · '
    '${maskPixKeyForDisplay(tipo, chave)}';

/// Leitura da chave mascarada sem soletrar asteriscos.
String walletChaveSemantica(String? tipo, String chave) {
  final raw = chave.trim();
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final t = (tipo ?? '').trim().toUpperCase();
  return switch (t) {
    'CPF' when digits.length >= 9 =>
      'CPF terminado em ${digits.substring(6, 9)}',
    'CNPJ' when digits.length >= 8 =>
      'CNPJ com ${digits.substring(2, 5)} ${digits.substring(5, 8)} no meio',
    'TELEFONE' when digits.length >= 4 =>
      'Celular terminado em ${digits.substring(digits.length - 4)}',
    'EMAIL' when raw.isNotEmpty => 'E-mail começando com ${raw[0]}',
    _ => 'Chave aleatória cadastrada',
  };
}

/// Tipos de chave, na ordem do seletor.
const walletTiposChave = ['CPF', 'CNPJ', 'EMAIL', 'TELEFONE', 'ALEATORIA'];

/// Rótulo curto para o seletor de tipo (cabe em uma fileira).
String walletTipoCurto(String tipo) => switch (tipo) {
  'CPF' => 'CPF',
  'CNPJ' => 'CNPJ',
  'EMAIL' => 'E-mail',
  'TELEFONE' => 'Celular',
  'ALEATORIA' => 'Aleatória',
  _ => tipo,
};

String walletPixSectionTitle() => 'Chave PIX';

/// Máscara para exibir chave PIX (CPF/CNPJ/telefone) sem PII completa.
String maskPixKeyForDisplay(String? tipo, String chave) {
  final raw = chave.trim();
  if (raw.isEmpty) return '';
  final t = (tipo ?? '').trim().toUpperCase();
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  switch (t) {
    case 'CPF':
      if (digits.length < 11) return '***.***.***-**';
      return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
    case 'CNPJ':
      if (digits.length < 14) return '**.***.***/****-**';
      return '**.${digits.substring(2, 5)}.${digits.substring(5, 8)}/****-**';
    case 'TELEFONE':
      if (digits.length < 8) return '(**) *****-****';
      return '(**) *****-${digits.substring(digits.length - 4)}';
    case 'EMAIL':
      final at = raw.indexOf('@');
      if (at <= 1) return '***@$raw';
      return '${raw[0]}***${raw.substring(at)}';
    default:
      if (raw.length <= 8) return '••••••••';
      return '${raw.substring(0, 4)}••••${raw.substring(raw.length - 4)}';
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 14) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

