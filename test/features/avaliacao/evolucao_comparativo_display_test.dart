import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/avaliacao/data/avaliacao_repository.dart';
import 'package:focux_app/features/avaliacao/utils/evolucao_comparativo_display.dart';

void main() {
  test('copy e formatação do comparativo', () {
    expect(evolucaoComparativoHubSubtitle(), 'Primeira vs atual avaliação');
    expect(evolucaoComparativoStickyShare(), 'Compartilhar no chat');
    expect(evolucaoComparativoStickyRegistrar(), 'Registrar avaliação');
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

  test('404 amigável conta como vazio', () {
    expect(evolucaoComparativoIsEmptyError('Recurso não encontrado.'), isTrue);
    expect(evolucaoComparativoIsEmptyError('Algo deu errado. Tente novamente.'), isFalse);
  });

  test('IMC deriva de peso e altura', () {
    expect(evolucaoComparativoImc(81, 180), closeTo(25.0, 0.1));
    expect(evolucaoComparativoImc(null, 180), isNull);
  });

  test('payload do BE usa ultima, não atual', () {
    final c = ComparativoEvolucao.fromJson({
      'primeira': {'pesoKg': 80, 'alturaCm': 180, 'percGordura': 22, 'cinturaCm': 80},
      'ultima': {'pesoKg': 78, 'alturaCm': 180, 'percGordura': 20, 'cinturaCm': 76},
      'diferencaPeso': -2.0,
    });
    expect(c.atual.pesoKg, 78);
    expect(c.atual.circCintura, 76);
    expect(c.diferencaPeso, -2);
    expect(
      evolucaoComparativoMetricas(primeira: c.primeira, atual: c.atual)
          .map((m) => m.label)
          .toList(),
      ['Peso', 'IMC', '% Gordura', 'Cintura'],
    );
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
