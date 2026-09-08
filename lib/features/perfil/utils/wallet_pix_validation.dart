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

  static List<TextInputFormatter> formattersForConta() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
      LengthLimitingTextInputFormatter(14),
    ];
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
const walletBancoMax = 80;
const walletAgenciaMax = 6;

String walletSalvarTooltip() => 'Salvar carteira';

String walletSalvarTileLabel() => 'Salvar dados';

String walletSalvarConfirmTitle() => 'Salvar dados da carteira?';

String walletSalvarConfirmMessage() =>
    'PIX e banco passam a valer nos recebimentos dos alunos.';

String walletDiscardTitle() => 'Descartar alterações?';

String walletDiscardMessage() =>
    'Você alterou dados da carteira. Se sair agora, as mudanças não serão salvas.';

String walletCopiarTileLabel() => 'Copiar chave PIX';

String walletHubSubtitle({String? freshness}) {
  const base = 'PIX e banco dos recebimentos';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

const walletDetalheSecaoPix = 'pix';
const walletDetalheSecaoBanco = 'banco';

const walletDetalheSecoes = [
  (value: walletDetalheSecaoPix, label: 'PIX'),
  (value: walletDetalheSecaoBanco, label: 'Banco'),
];

String walletTipoChipLabel(String? tipo) {
  if (tipo == null || tipo.trim().isEmpty) return 'Tipo de chave';
  return WalletPixValidation.labelForTipo(tipo);
}

String walletPixSectionTitle() => 'Dados PIX';

String walletBancoSectionTitle() => 'Dados bancários';

String walletVerFinanceiroLabel() => 'Ver financeiro';

String walletRecebidoHint({
  required String previsto,
  required int percent,
}) => '$percent% de $previsto previsto';

String walletPixStatusValue(String? tipo, String chave) {
  final temTipo = tipo != null && tipo.trim().isNotEmpty;
  final temChave = chave.trim().isNotEmpty;
  if (temTipo && temChave) return 'Pronta';
  return 'Pendente';
}

String walletPixStatusHint(String? tipo, String chave) {
  final temTipo = tipo != null && tipo.trim().isNotEmpty;
  final temChave = chave.trim().isNotEmpty;
  if (temTipo && temChave) {
    return WalletPixValidation.labelForTipo(tipo);
  }
  if (!temTipo && !temChave) return 'Falta tipo e chave';
  if (!temTipo) return 'Falta o tipo da chave';
  return 'Falta a chave PIX';
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

