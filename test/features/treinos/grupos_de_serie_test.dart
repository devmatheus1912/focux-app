import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/grupos_de_serie.dart';
import 'package:focux_app/features/treinos/utils/prescricao_serie.dart';

/// O exemplo do MFIT: 2 × 10-15 aquecimento, 1 × 4-6 ajuste, 2 × 2-4 ajuste,
/// 2 × 6-10 válidas, cada grupo com o seu descanso.
void main() {
  List<SeriePrescrita> mfit() => desagruparSeries(const [
    GrupoDeSeries(papel: PapelDaSerie.aquecimento, series: 2, repeticoes: '10-15', descansoSegundos: 60),
    GrupoDeSeries(papel: PapelDaSerie.ajuste, series: 1, repeticoes: '4-6', descansoSegundos: 90),
    GrupoDeSeries(papel: PapelDaSerie.ajuste, series: 2, repeticoes: '2-4', descansoSegundos: 90),
    GrupoDeSeries(papel: PapelDaSerie.valida, series: 2, repeticoes: '6-10', cargaKg: 40, descansoSegundos: 120),
  ]);

  test('desagrupar numera em ordem e agrupar volta aos mesmos grupos', () {
    final linhas = mfit();
    expect(linhas.map((l) => l.numero), [1, 2, 3, 4, 5, 6, 7]);
    expect(linhas[2].papel, PapelDaSerie.ajuste);
    expect(linhas[6].descansoSegundos, 120);
    final grupos = agruparSeries(linhas);
    expect(grupos, hasLength(4));
    expect(grupos[2].repeticoes, '2-4');
    expect(grupos[2].series, 2);
  });

  test('extras: aquecimento e ajuste antes, back-off depois', () {
    final linhas = [
      ...mfit(),
      const SeriePrescrita(numero: 8, repeticoes: '8-12', papel: PapelDaSerie.backoff),
    ];
    final extras = gruposExtras(linhas);
    expect(extras.antes.map((g) => g.papel), [
      PapelDaSerie.aquecimento,
      PapelDaSerie.ajuste,
      PapelDaSerie.ajuste,
    ]);
    expect(extras.depois.single.papel, PapelDaSerie.backoff);
  });

  test('back-off sugerido: 2 séries, mesmas reps, 80% da carga em 0,5 kg', () {
    final b = grupoSugerido(
      PapelDaSerie.backoff,
      seriesValidas: 4,
      repsValidas: '8-12',
      cargaValidas: 47,
      descansoValidas: 90,
    );
    expect(b.series, 2);
    expect(b.repeticoes, '8-12');
    expect(b.cargaKg, 37.5);
    expect(b.descansoSegundos, 90);
  });

  test('resumo da linha com grupos; um grupo só fica como hoje', () {
    expect(resumoDosGrupos(mfit()), '2 aquec. · 3 ajuste · 2 × 6-10 · 120 s');
    expect(
      resumoDosGrupos(const [
        SeriePrescrita(numero: 1, repeticoes: '8-12'),
        SeriePrescrita(numero: 2, repeticoes: '8-12'),
      ]),
      isNull,
    );
  });

  test('só válida e back-off contam', () {
    expect(PapelDaSerie.conta(PapelDaSerie.valida), isTrue);
    expect(PapelDaSerie.conta(PapelDaSerie.backoff), isTrue);
    expect(PapelDaSerie.conta(PapelDaSerie.aquecimento), isFalse);
    expect(PapelDaSerie.conta(PapelDaSerie.ajuste), isFalse);
  });
}
