import '../../../core/utils/fx_utils.dart';

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

String evolucaoComparativoShareTooltip() => 'Compartilhar no chat';

String evolucaoComparativoShareTileLabel() => 'Compartilhar via Chat';

String evolucaoComparativoShareTileValue() => 'Enviar resumo';

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
