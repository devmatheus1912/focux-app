import '../../../core/utils/fx_utils.dart';
import '../data/avaliacao_repository.dart';

enum EvolucaoComparativoDeltaTone { better, worse, same, missing }

class EvolucaoComparativoDelta {
  const EvolucaoComparativoDelta({
    required this.text,
    required this.tone,
  });

  final String text;
  final EvolucaoComparativoDeltaTone tone;

  bool get hasIcon =>
      tone == EvolucaoComparativoDeltaTone.better ||
      tone == EvolucaoComparativoDeltaTone.worse;

  bool get improved => tone == EvolucaoComparativoDeltaTone.better;
}

String evolucaoComparativoHubSubtitle() => 'Primeira vs atual avaliação';

String evolucaoComparativoStickyShare() => 'Compartilhar no chat';

String evolucaoComparativoStickyRegistrar() => 'Registrar avaliação';

bool evolucaoComparativoIsEmptyError(String message) {
  final lower = message.toLowerCase();
  return lower.contains('404') ||
      lower.contains('not found') ||
      lower.contains('não encontrado') ||
      lower.contains('nao encontrado') ||
      lower.contains('nenhuma avaliação') ||
      lower.contains('nenhuma avaliacao');
}

String evolucaoComparativoPesoMetricHint(double? delta) {
  if (delta == null) return 'Peso da última avaliação';
  if (delta == 0) return 'Peso igual ao da primeira';
  final signed = '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg';
  return 'Desde a primeira: $signed';
}

double? evolucaoComparativoImc(double? pesoKg, double? alturaCm) {
  if (pesoKg == null || alturaCm == null || alturaCm <= 0) return null;
  final metros = alturaCm / 100;
  return pesoKg / (metros * metros);
}

class EvolucaoComparativoMetrica {
  const EvolucaoComparativoMetrica({
    required this.label,
    required this.unidade,
    required this.primeira,
    required this.atual,
    required this.menorEMelhor,
  });

  final String label;
  final String unidade;
  final double? primeira;
  final double? atual;
  final bool menorEMelhor;

  bool get visivel => primeira != null || atual != null;
}

List<EvolucaoComparativoMetrica> evolucaoComparativoMetricas({
  required SnapshotAvaliacao primeira,
  required SnapshotAvaliacao atual,
}) {
  return [
    EvolucaoComparativoMetrica(
      label: 'Peso',
      unidade: 'kg',
      primeira: primeira.pesoKg,
      atual: atual.pesoKg,
      menorEMelhor: true,
    ),
    EvolucaoComparativoMetrica(
      label: 'IMC',
      unidade: '',
      primeira: primeira.imc ?? evolucaoComparativoImc(primeira.pesoKg, primeira.alturaCm),
      atual: atual.imc ?? evolucaoComparativoImc(atual.pesoKg, atual.alturaCm),
      menorEMelhor: true,
    ),
    EvolucaoComparativoMetrica(
      label: '% Gordura',
      unidade: '%',
      primeira: primeira.percGordura,
      atual: atual.percGordura,
      menorEMelhor: true,
    ),
    EvolucaoComparativoMetrica(
      label: '% Massa',
      unidade: '%',
      primeira: primeira.percMassa,
      atual: atual.percMassa,
      menorEMelhor: false,
    ),
    EvolucaoComparativoMetrica(
      label: 'Massa muscular',
      unidade: 'kg',
      primeira: primeira.massaMuscular,
      atual: atual.massaMuscular,
      menorEMelhor: false,
    ),
    EvolucaoComparativoMetrica(
      label: 'Cintura',
      unidade: 'cm',
      primeira: primeira.circCintura,
      atual: atual.circCintura,
      menorEMelhor: true,
    ),
    EvolucaoComparativoMetrica(
      label: 'Quadril',
      unidade: 'cm',
      primeira: primeira.circQuadril,
      atual: atual.circQuadril,
      menorEMelhor: true,
    ),
    EvolucaoComparativoMetrica(
      label: 'Braço',
      unidade: 'cm',
      primeira: primeira.circBraco,
      atual: atual.circBraco,
      menorEMelhor: false,
    ),
    EvolucaoComparativoMetrica(
      label: 'Coxa',
      unidade: 'cm',
      primeira: primeira.circCoxa,
      atual: atual.circCoxa,
      menorEMelhor: false,
    ),
  ].where((row) => row.visivel).toList();
}

String evolucaoComparativoConfirmTitle() => 'Compartilhar no chat?';

String evolucaoComparativoConfirmMessage() =>
    'O aluno recebe um resumo da evolução na conversa com você.';

String evolucaoComparativoConfirmLabel() => 'Enviar';

String evolucaoComparativoJanelaCaption({
  required String primeira,
  required String atual,
}) =>
    'Primeira $primeira · Atual $atual';

String evolucaoComparativoFmtData(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    return fxDateShort(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

String evolucaoComparativoFmtNum(double? value, {int decimais = 1}) {
  if (value == null) return '—';
  return value.toStringAsFixed(decimais);
}

String evolucaoComparativoFmtValor(double? value, String unidade) {
  if (value == null) return '—';
  final suffix = unidade.isEmpty ? '' : ' $unidade';
  return '${evolucaoComparativoFmtNum(value)}$suffix';
}

EvolucaoComparativoDelta evolucaoComparativoDelta({
  required double? primeira,
  required double? atual,
  required bool menorEMelhor,
  int decimais = 1,
}) {
  if (primeira == null || atual == null) {
    return const EvolucaoComparativoDelta(
      text: '—',
      tone: EvolucaoComparativoDeltaTone.missing,
    );
  }
  final diff = atual - primeira;
  final text = '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(decimais)}';
  if (diff == 0) {
    return EvolucaoComparativoDelta(
      text: text,
      tone: EvolucaoComparativoDeltaTone.same,
    );
  }
  final melhorou = menorEMelhor ? diff < 0 : diff > 0;
  return EvolucaoComparativoDelta(
    text: text,
    tone:
        melhorou
            ? EvolucaoComparativoDeltaTone.better
            : EvolucaoComparativoDeltaTone.worse,
  );
}
