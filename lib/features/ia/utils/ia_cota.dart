/// A cota de IA é por mês do calendário: volta no dia 1, não na cobrança.
DateTime iaCotaVoltaEm(DateTime agora) => DateTime(agora.year, agora.month + 1);

String iaCotaVoltaLabel(DateTime agora) {
  final volta = iaCotaVoltaEm(agora);
  final dia = volta.day.toString().padLeft(2, '0');
  final mes = volta.month.toString().padLeft(2, '0');
  return '$dia/$mes';
}

enum IaCotaTom { normal, atencao, esgotada }

/// Atenção a partir de 80% do limite, igual a `PlanoFeatures.iaNearLimit`.
IaCotaTom iaCotaTom({required int usado, required int limite}) {
  if (limite > 0 && usado >= limite) return IaCotaTom.esgotada;
  if (limite > 0 && usado >= (limite * 0.8).ceil()) return IaCotaTom.atencao;
  return IaCotaTom.normal;
}

String iaCotaUsoTexto({
  required int usado,
  required int limite,
  required DateTime agora,
}) => '$usado de $limite usos de IA · volta em ${iaCotaVoltaLabel(agora)}';

String iaCotaEsgotadaTexto({required int limite, required DateTime agora}) =>
    'Seus $limite usos de IA acabaram. Voltam em ${iaCotaVoltaLabel(agora)}.';
