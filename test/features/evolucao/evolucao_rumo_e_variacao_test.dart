import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_medida_plausivel.dart';
import 'package:focux_app/features/avaliacao/utils/evolucao_comparativo_display.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/data/meta_corporal.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_series.dart';

MetaCorporal _meta({
  required double inicio,
  required double alvo,
  String tipo = 'META',
  bool foraDaFaixa = false,
}) => MetaCorporal(
  id: 1,
  metrica: 'CINTURA',
  tipo: tipo,
  valorInicial: inicio,
  valorAlvo: alvo,
  progresso: 0,
  status: 'ATIVA',
  foraDaFaixa: foraDaFaixa,
);

void main() {
  group('rumoDaMeta', () {
    test('cintura subindo com meta de descer está se afastando', () {
      expect(rumoDaMeta(_meta(inicio: 60, alvo: 30), 70), RumoDaMeta.seAfastando);
    });

    test('braço subindo com meta de subir está no rumo', () {
      expect(rumoDaMeta(_meta(inicio: 50, alvo: 70), 55), RumoDaMeta.noRumo);
    });

    test('sem meta ou sem mudança não diz nada', () {
      expect(rumoDaMeta(null, 70), isNull);
      expect(rumoDaMeta(_meta(inicio: 60, alvo: 30), 60), isNull);
    });

    test('manutenção vale pela faixa', () {
      expect(
        rumoDaMeta(_meta(inicio: 110, alvo: 110, tipo: 'MANUTENCAO'), 112),
        RumoDaMeta.noRumo,
      );
      expect(
        rumoDaMeta(
          _meta(inicio: 110, alvo: 110, tipo: 'MANUTENCAO', foraDaFaixa: true),
          120,
        ),
        RumoDaMeta.seAfastando,
      );
    });
  });

  group('variacaoSuspeita', () {
    test('peso: 1,5 kg por dia', () {
      expect(variacaoSuspeita('kg', 20, 5), isTrue);
      expect(variacaoSuspeita('kg', 1.2, 1), isFalse);
      expect(variacaoSuspeita('kg', -8, 30), isFalse);
    });

    test('percentual: 3 pontos por semana, janela mínima de uma semana', () {
      expect(variacaoSuspeita('%', 70, 5), isTrue);
      expect(variacaoSuspeita('%', 2.5, 2), isFalse);
      expect(variacaoSuspeita('%', 6, 14), isFalse);
    });

    test('IMC (sem unidade) não é checado aqui', () {
      expect(variacaoSuspeita('', 10, 1), isFalse);
    });
  });

  test('nova medida: 90 → 110 kg em 5 dias pede conferência', () {
    final itens = variacoesSuspeitas(
      data: '2026-11-04',
      medidas: [MedidaCorporal(id: 1, data: '2026-10-30', peso: 90, cintura: 70)],
      peso: 110,
      cintura: 70.5,
    );
    expect(itens, ['Peso +20,0 kg em 5 dias']);
  });

  test('1RM some em abdominal e fica em supino', () {
    RecordePessoal r(String nome) => RecordePessoal(
      id: 1,
      exercicioId: 1,
      exercicioNome: nome,
      data: '2026-11-04',
      cargaKg: 50,
      repeticoes: 8,
    );
    expect(umRmEstimado(r('Abdominal completo (sit-up) no banco declinado')), isNull);
    expect(umRmEstimado(r('Supino reto')), isNotNull);
  });

  test('1RM vai pelo grupo muscular quando o servidor manda', () {
    RecordePessoal r(String nome, String grupo) => RecordePessoal(
      id: 1,
      exercicioId: 1,
      exercicioNome: nome,
      data: '2026-11-04',
      cargaKg: 40,
      repeticoes: 10,
      grupoMuscular: grupo,
    );
    expect(umRmEstimado(r('Elevação de pernas', 'ABDOMEN')), isNull);
    expect(umRmEstimado(r('Remada com abdominal no nome', 'COSTAS_LATISSIMO')), isNotNull);
    expect(
      RecordePessoal.fromJson({
        'id': 1,
        'exercicioId': 2,
        'exercicioNome': 'Supino',
        'data': '2026-11-04',
        'grupoMuscular': 'PEITO',
      }).grupoMuscular,
      'PEITO',
    );
  });

  group('Comparar', () {
    const massa = EvolucaoComparativoMetrica(
      label: 'Massa magra',
      unidade: '%',
      primeira: 10,
      atual: 80,
      menorEMelhor: false,
    );

    test('percentual muda em pontos', () {
      expect(evolucaoComparativoDiferenca(massa), '↑ 70,0 pp');
    });

    test('variação fora do comum é marcada', () {
      expect(evolucaoComparativoSuspeita(massa, 5), isTrue);
      expect(
        evolucaoComparativoSuspeita(
          const EvolucaoComparativoMetrica(
            label: 'Peso',
            unidade: 'kg',
            primeira: 80,
            atual: 79,
            menorEMelhor: true,
          ),
          7,
        ),
        isFalse,
      );
    });
  });
}
