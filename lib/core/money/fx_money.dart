/// Dinheiro em centavos. Evita `double` em soma, comparação e JSON de reais.
class FxMoney implements Comparable<FxMoney> {
  const FxMoney.cents(this.cents);

  static const zero = FxMoney.cents(0);

  final int cents;

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

String formatBrlCents(int cents, {bool showDecimals = true}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final reais = abs ~/ 100;
  final frac = abs % 100;
  final intText = reais.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < intText.length; i++) {
    if (i > 0 && (intText.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(intText[i]);
  }
  final decimals = showDecimals ? ',${frac.toString().padLeft(2, '0')}' : '';
  final prefix = negative ? '-' : '';
  return '$prefix R\$ ${buffer.toString()}$decimals'.replaceFirst(' ', '');
}
