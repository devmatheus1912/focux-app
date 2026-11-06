import '../../../core/utils/fx_utils.dart';
import '../data/avaliacao_repository.dart';
import '../../alunos/utils/aluno360_medida_plausivel.dart';
import '../../../core/utils/pt_br_display.dart';

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
      label: 'Massa magra',
      unidade: '%',
      primeira: primeira.percMassa ?? primeira.massaMuscular,
      atual: atual.percMassa ?? atual.massaMuscular,
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

/// "30/10 → 02/11 · 3 dias".
String evolucaoComparativoJanelaCaption({
  required String primeira,
  required String atual,
  int? dias,
}) =>
    '$primeira → $atual${dias == null ? '' : ' · $dias ${dias == 1 ? 'dia' : 'dias'}'}';

/// Dias de calendário: avaliação de 30/10 à noite e de 02/11 de manhã são
/// 3 dias, não os 2 que sairiam contando blocos de 24 h.
int? evolucaoComparativoDias(String? primeira, String? atual) {
  final a = DateTime.tryParse(primeira ?? '');
  final b = DateTime.tryParse(atual ?? '');
  if (a == null || b == null) return null;
  final diaA = DateTime.utc(a.year, a.month, a.day);
  final diaB = DateTime.utc(b.year, b.month, b.day);
  return diaB.difference(diaA).inDays;
}

/// Diferença com unidade e seta neutra; "=" sem mudança. Percentual muda em
/// pontos: 20% → 25% é "↑ 5,0 pp", não "5,0 %".
String evolucaoComparativoDiferenca(EvolucaoComparativoMetrica m) {
  final diferenca = m.atual! - m.primeira!;
  if (diferenca == 0) return '=';
  final seta = diferenca > 0 ? '↑' : '↓';
  final unidade = switch (m.unidade) {
    '' => '',
    '%' => ' pp',
    final u => ' $u',
  };
  return '$seta ${evolucaoComparativoFmtNum(diferenca.abs())}$unidade';
}

/// Mudança grande demais para o intervalo ([variacaoSuspeita]): a linha
/// pede conferência antes de virar o antes e depois do aluno.
bool evolucaoComparativoSuspeita(EvolucaoComparativoMetrica m, int? dias) {
  if (m.primeira == null || m.atual == null || dias == null) return false;
  return variacaoSuspeita(m.unidade, m.atual! - m.primeira!, dias);
}

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
  return formatBrDecimal(value, digits: decimais);
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
  final text = '${diff >= 0 ? '+' : ''}${formatBrDecimal(diff, digits: decimais)}';
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
