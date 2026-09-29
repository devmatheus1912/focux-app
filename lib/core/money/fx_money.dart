/// Dinheiro em centavos. Evita `double` em soma, comparação e JSON de reais.
class FxMoney implements Comparable<FxMoney> {
  const FxMoney.cents(this.cents);

  static const zero = FxMoney.cents(0);

  final int cents;

  /// Reais só para parser legado. Soma e comparação usam [cents].
  double get asReais => cents / 100.0;

  /// Aceita string JSON ou número antigo sem estourar o `as num`.
  static double reais(Object? raw) => FxMoney.parse(raw ?? 0).asReais;

  factory FxMoney.parse(Object? raw) {
    if (raw == null) return zero;
    if (raw is FxMoney) return raw;
    if (raw is int) return FxMoney.cents(raw * 100);
    if (raw is String) return FxMoney.fromInput(raw);
    if (raw is num) return FxMoney.fromInput(raw.toString());
    return FxMoney.fromInput(raw.toString());
  }

  factory FxMoney.fromInput(String text) {
    var value = text.trim();
    if (value.isEmpty) {
      throw const FormatException('Informe o valor');
    }
    value = value.replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (value.isEmpty || value == '-' || value == '.' || value == ',') {
      throw const FormatException('Informe o valor');
    }
    if (value.contains(',') && value.contains('.')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (value.contains(',')) {
      value = value.replaceAll(',', '.');
    }
    final parsed = num.tryParse(value);
    if (parsed == null) {
      throw const FormatException('Informe o valor');
    }
    return FxMoney.cents((parsed * 100).round());
  }

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;

  FxMoney get positiveOrZero => cents < 0 ? zero : this;

  /// `"1200.50"` — Jackson lê como BigDecimal sem passar por float do app.
  String get wire {
    final sign = cents < 0 ? '-' : '';
    final abs = cents.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  String format({bool showDecimals = true}) =>
      formatBrlCents(cents, showDecimals: showDecimals);

  /// Valor cobrado ou pago (mensalidade, PIX, total a pagar): nunca sem centavos.
  String formatCobranca() => formatBrlCents(cents);

  /// KPI agregado sem centavos, arredondado — ver [formatBrlCompact].
  String formatCompact() => formatBrlCompact(cents);

  double ratioOf(FxMoney other) {
    if (other.cents == 0) return 0;
    return cents / other.cents;
  }

  FxMoney operator +(FxMoney other) => FxMoney.cents(cents + other.cents);

  FxMoney operator -(FxMoney other) => FxMoney.cents(cents - other.cents);

  bool operator >(FxMoney other) => cents > other.cents;

  bool operator >=(FxMoney other) => cents >= other.cents;

  bool operator <(FxMoney other) => cents < other.cents;

  bool operator <=(FxMoney other) => cents <= other.cents;

  @override
  int compareTo(FxMoney other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is FxMoney && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => wire;
}

/// `showDecimals: false` é o mesmo que [formatBrlCompact] (arredonda).
String formatBrlCents(int cents, {bool showDecimals = true}) {
  if (!showDecimals) return formatBrlCompact(cents);
  final abs = cents.abs();
  final frac = (abs % 100).toString().padLeft(2, '0');
  return _brl(negative: cents < 0, reais: abs ~/ 100, decimals: ',$frac');
}

/// KPI agregado (recebido, previsto, ticket): reais inteiros arredondados
/// meio-para-cima. Nunca trunca — R$ 149,90 vira "R$ 150".
String formatBrlCompact(int cents) {
  final reais = (cents.abs() + 50) ~/ 100;
  return _brl(negative: cents < 0 && reais > 0, reais: reais);
}

String _brl({required bool negative, required int reais, String decimals = ''}) {
  final intText = reais.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < intText.length; i++) {
    if (i > 0 && (intText.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(intText[i]);
  }
  final prefix = negative ? '-' : '';
  return '${prefix}R\$ ${buffer.toString()}$decimals';
}
