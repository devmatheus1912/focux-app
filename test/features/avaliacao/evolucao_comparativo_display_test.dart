import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/avaliacao/utils/evolucao_comparativo_display.dart';

void main() {
  test('copy e formatação do comparativo', () {
    expect(evolucaoComparativoHubSubtitle(), 'Primeira vs atual avaliação');
    expect(evolucaoComparativoShareTooltip(), 'Compartilhar no chat');
    expect(evolucaoComparativoShareTileLabel(), 'Compartilhar via Chat');
    expect(evolucaoComparativoConfirmTitle(), 'Compartilhar no chat?');
    expect(evolucaoComparativoConfirmLabel(), 'Enviar');
    expect(
      evolucaoComparativoJanelaCaption(primeira: '01/01', atual: '01/02'),
      'Primeira 01/01 · Atual 01/02',
    );
    expect(evolucaoComparativoFmtData(null), '—');
    expect(evolucaoComparativoFmtData(''), '—');
    expect(evolucaoComparativoFmtData('nao-e-data'), 'nao-e-data');
    expect(evolucaoComparativoFmtNum(null), '—');
    expect(evolucaoComparativoFmtNum(72.46), '72.5');
    expect(evolucaoComparativoFmtValor(null, 'kg'), '—');
    expect(evolucaoComparativoFmtValor(80, 'kg'), '80.0 kg');
    expect(evolucaoComparativoFmtValor(22.1, ''), '22.1');
  });

  test('delta respeita o sentido da métrica', () {
    final downGood = evolucaoComparativoDelta(
      primeira: 80,
      atual: 78,
      menorEMelhor: true,
    );
    expect(downGood.text, '-2.0');
    expect(downGood.tone, EvolucaoComparativoDeltaTone.better);
    expect(downGood.improved, isTrue);

    final upBad = evolucaoComparativoDelta(
      primeira: 80,
      atual: 82,
      menorEMelhor: true,
    );
    expect(upBad.text, '+2.0');
    expect(upBad.tone, EvolucaoComparativoDeltaTone.worse);

    final upGood = evolucaoComparativoDelta(
      primeira: 40,
      atual: 42,
      menorEMelhor: false,
    );
    expect(upGood.tone, EvolucaoComparativoDeltaTone.better);

    final same = evolucaoComparativoDelta(
      primeira: 70,
      atual: 70,
      menorEMelhor: true,
    );
    expect(same.text, '+0.0');
    expect(same.tone, EvolucaoComparativoDeltaTone.same);
    expect(same.hasIcon, isFalse);

    final missing = evolucaoComparativoDelta(
      primeira: null,
      atual: 70,
      menorEMelhor: true,
    );
    expect(missing.text, '—');
    expect(missing.tone, EvolucaoComparativoDeltaTone.missing);
  });
}
