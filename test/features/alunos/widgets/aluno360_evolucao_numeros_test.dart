import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_core_models.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart';

/// Tendência, volume e recorde viram números lado a lado; a sugestão tem
/// rótulo (antes: três chips coloridos e uma frase solta).
void main() {
  EvolucaoInteligente ev({int? pct, String sinal = 'ESTÁVEL'}) =>
      EvolucaoInteligente(
        sinal: sinal,
        resumo: 'Ritmo de treino estável.',
        volumeSemanal: 1500,
        volumeMensal: 6000,
        tendenciaVolumePct: pct,
      );

  test('tendência com sinal e %', () {
    expect(Aluno360EvolucaoInteligenteCard.tendenciaTexto(ev(pct: 3)), 'Estável · +3%');
    expect(Aluno360EvolucaoInteligenteCard.tendenciaTexto(ev(pct: -12)), 'Estável · -12%');
  });

  test('% absurdo de base pequena fica só com o sinal', () {
    expect(
      Aluno360EvolucaoInteligenteCard.tendenciaTexto(ev(pct: 596, sinal: 'SUBINDO')),
      'Em alta',
    );
    expect(Aluno360EvolucaoInteligenteCard.tendenciaTexto(ev()), 'Estável');
  });
}
