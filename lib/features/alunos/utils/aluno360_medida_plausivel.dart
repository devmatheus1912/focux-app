import '../../../core/utils/pt_br_display.dart';

enum MedidaTipo { pesoKg, gorduraPct, massaMagraPct, alturaM }

/// Faixa que um adulto real pode ter. Fora dela, a tela pede para o personal
/// confirmar o valor em vez de mostrá-lo como normal.
bool medidaPlausivel(MedidaTipo tipo, double valor) => switch (tipo) {
  MedidaTipo.pesoKg => valor >= 20 && valor <= 300,
  MedidaTipo.gorduraPct => valor >= 3 && valor <= 60,
  MedidaTipo.massaMagraPct => valor >= 20 && valor <= 95,
  MedidaTipo.alturaM => valor >= 0.5 && valor <= 2.5,
};

/// Lê "818,0%", "818.0 %" ou "51,0 kg"; nulo se não houver número.
double? lerNumeroDaMedida(String? texto) {
  final m = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(texto ?? '');
  if (m == null) return null;
  return double.tryParse(m.group(0)!.replaceAll(',', '.'));
}

/// Valores do formulário "Nova medida" que parecem digitados errado, já
/// formatados ("Peso 458,0 kg"). Vazia quando está tudo dentro da faixa.
List<String> medidasSuspeitas({
  double? peso,
  double? gordura,
  double? massaMagra,
}) => [
  if (peso != null && !medidaPlausivel(MedidaTipo.pesoKg, peso))
    'Peso ${formatBrDecimal(peso)} kg',
  if (gordura != null && !medidaPlausivel(MedidaTipo.gorduraPct, gordura))
    'Gordura ${formatBrDecimal(gordura)}%',
  if (massaMagra != null && !medidaPlausivel(MedidaTipo.massaMagraPct, massaMagra))
    'Massa magra ${formatBrDecimal(massaMagra)}%',
];

/// Quanto uma medida pode mudar de verdade entre dois registros, pela
/// unidade: peso até 1,5 kg por dia, circunferência até 1 cm por dia e
/// percentual até 3 pontos por semana (com janela mínima de uma semana).
/// Passou disso, é mais provável erro de digitação do que evolução.
bool variacaoSuspeita(String unidade, double diferenca, int dias) {
  final d = dias < 1 ? 1 : dias;
  final limite = switch (unidade) {
    'kg' => 1.5 * d,
    'cm' => 1.0 * d,
    '%' => 3.0 * (d < 7 ? 7 : d) / 7,
    _ => double.infinity,
  };
  return diferenca.abs() > limite;
}
