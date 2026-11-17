import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/models/checkin_execucao_models.dart';
import 'package:focux_app/features/checkin/utils/checkin_execucao_estado.dart';
import 'package:focux_app/features/checkin/utils/checkin_serie_input.dart';
import 'package:focux_app/features/checkin/utils/checkin_serie_textos.dart';
import 'package:focux_app/features/checkin/utils/execucao_metodos.dart';
import 'package:focux_app/features/checkin/utils/serie_de_agora.dart';
import 'package:focux_app/features/treinos/models/metodo_exercicio.dart';
import 'package:focux_app/features/treinos/utils/prescricao_serie.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';

final s = SPt();

/// 2 aquecimentos + 4 válidas em pirâmide ↑ (15 → 9), drop-set só na última.
ExecucaoExercicio _piramideComDrop({int feitas = 0, List<ExecucaoSerie> anteriores = const []}) =>
    ExecucaoExercicio(
      id: 1,
      treinoExercicioId: 1,
      exercicioNome: 'Desenvolvimento',
      series: 6,
      repeticoes: '15',
      descansoSegundos: 60,
      seriesFeitas: feitas,
      concluido: false,
      metodo: const MetodoExercicio(
        tecnica: Tecnica.dropset,
        progressao: Progressao.piramideCrescente,
        quedas: 2,
        reducaoPct: 20,
      ),
      seriesAnteriores: anteriores,
      seriesPrescritas: const [
        SeriePrescrita(numero: 1, repeticoes: '4-6', papel: 'AQUECIMENTO', descansoSegundos: 30),
        SeriePrescrita(numero: 2, repeticoes: '4-6', papel: 'AQUECIMENTO', descansoSegundos: 30),
        SeriePrescrita(numero: 3, repeticoes: '15', cargaKg: 10, descansoSegundos: 45),
        SeriePrescrita(numero: 4, repeticoes: '13', cargaKg: 11, descansoSegundos: 45),
        SeriePrescrita(numero: 5, repeticoes: '11', cargaKg: 12, descansoSegundos: 45),
        SeriePrescrita(numero: 6, repeticoes: '9', cargaKg: 13, descansoSegundos: 45, tecnica: 'DROPSET'),
      ],
    );

void main() {
  test('série guardada sem internet: a próxima usa a meta dela (pirâmide 15 → 13)', () {
    final ee = _piramideComDrop(feitas: 2);
    final depois = checkinAplicarSerieLocal(
      ee,
      const CheckinSeriePendente(execucaoId: 1, treinoExercicioId: 1, numero: 3, cargaKg: 10, repeticoes: '15'),
    );
    final semente = CheckinRascunhos().de(depois);
    expect((semente.cargaKg, semente.reps), (11.0, 13));
    expect(serieDeAgora(depois).descanso, 45);
  });

  test('prescrição nova com o mesmo nº de séries: o aquecimento usa a meta, não a sessão passada', () {
    final ee = _piramideComDrop(anteriores: [
      for (var n = 1; n <= 6; n++) ExecucaoSerie(id: n, numero: n, cargaKg: 10, repeticoes: '10'),
    ]);
    final sa = serieDeAgora(ee);
    expect(sa.repsSugeridas, 4);
    expect(sa.cargaSugerida, isNull, reason: 'aquecimento não herda carga de válida');
  });

  test('cabeçalho, meta, botão e "Depois" por série', () {
    final ee = _piramideComDrop(feitas: 2);
    final v1 = serieDeAgora(ee);
    expect(v1.rotulo, 'Válida 1 de 4');
    expect(checkinCabecalhoDaSerie(v1, ee.metodo), 'Válida 1 de 4 · Pirâmide ↑');
    expect(checkinMetaDaSerie(s, v1), 'Meta: 15 reps · 10 kg · descanso 45 s');
    expect(checkinBotaoDaSerie(s, v1), 'Registrar válida 1');
    expect(checkinTextoDepois(s, ee, 'Supino'), 'Depois: Válida 2 · 13 reps · 11 kg');

    final a1 = serieDeAgora(_piramideComDrop());
    expect(checkinCabecalhoDaSerie(a1, ee.metodo), 'Aquecimento 1 de 2');
    expect(checkinMetaDaSerie(s, a1), 'Meta: 4-6 reps · descanso 30 s');
    expect(a1.rotuloDaBolinha, 'A');
  });

  test('técnica só na série marcada: cabeçalho, instrução, "Depois" e folha de passos', () {
    final antesDaUltima = _piramideComDrop(feitas: 4);
    expect(checkinTextoDepois(s, antesDaUltima, 'Supino'), 'Depois: Válida 4 · 9 reps · 13 kg · Drop-set');

    final ultima = serieDeAgora(_piramideComDrop(feitas: 5));
    expect(checkinCabecalhoDaSerie(ultima, antesDaUltima.metodo), 'Válida 4 de 4 · Pirâmide ↑ · Drop-set');
    expect(checkinInstrucaoDaSerie(s, ultima, antesDaUltima.metodo), 'Depois: 2 quedas de 20%, sem descanso');

    // A folha do drop não abre no aquecimento nem nas válidas sem marca.
    for (final n in [1, 2, 3, 4, 5]) {
      final sa = serieDeAgora(_piramideComDrop(feitas: n), numero: n);
      expect(passosDoMetodo(antesDaUltima.metodo, tecnica: sa.tecnica), isEmpty, reason: 'série $n');
    }
    expect(passosDoMetodo(antesDaUltima.metodo, tecnica: ultima.tecnica, cargaDaSerie: 13).length, 2);
  });

  test('técnicas de tempo: instrução antes, sem passo depois; parciais: um passo', () {
    const pico = MetodoExercicio(tecnica: Tecnica.pico, segundos: 2);
    final ee = ExecucaoExercicio(
      id: 1,
      treinoExercicioId: 1,
      exercicioNome: 'Rosca',
      series: 3,
      repeticoes: '10',
      seriesFeitas: 0,
      concluido: false,
      metodo: pico,
      seriesPrescritas: const [
        SeriePrescrita(numero: 1, repeticoes: '10', tecnica: 'PICO'),
        SeriePrescrita(numero: 2, repeticoes: '10', tecnica: 'PICO'),
        SeriePrescrita(numero: 3, repeticoes: '10', tecnica: 'PICO'),
      ],
    );
    final sa = serieDeAgora(ee);
    expect(sa.rotulo, 'Série 1 de 3');
    expect(checkinInstrucaoDaSerie(s, sa, pico), 'Segure 2 s no alto de cada repetição');
    expect(passosDoMetodo(pico, tecnica: sa.tecnica), isEmpty);
    expect(
      passosDoMetodo(const MetodoExercicio(tecnica: Tecnica.parciais, parciais: 8)).single.titulo,
      'Mais 8 parciais',
    );
  });

  test('backend antigo sem linhas: meta da próxima vem do servidor e a técnica vale em todas', () {
    final ee = ExecucaoExercicio(
      id: 1,
      treinoExercicioId: 1,
      exercicioNome: 'Supino',
      series: 4,
      repeticoes: '8-12',
      seriesFeitas: 1,
      concluido: false,
      proximaRepeticoes: '10',
      proximaCargaKg: 40,
      metodo: const MetodoExercicio(tecnica: Tecnica.restpause),
    );
    final sa = serieDeAgora(ee);
    expect((sa.repsSugeridas, sa.cargaSugerida), (10, 40.0));
    expect(sa.tecnica, Tecnica.restpause);
    expect(checkinBotaoDaSerie(s, sa), 'Registrar série 2');
  });

  test('"Última vez nesta série" pega a mesma série da sessão passada', () {
    final ee = _piramideComDrop(feitas: 3, anteriores: const [
      ExecucaoSerie(id: 1, numero: 4, cargaKg: 11, repeticoes: '12'),
      ExecucaoSerie(id: 2, numero: 6, cargaKg: 14, repeticoes: '8'),
    ]);
    expect(ultimaVezDaSerie(ee), (cargaKg: 11.0, reps: 12));
  });
}
