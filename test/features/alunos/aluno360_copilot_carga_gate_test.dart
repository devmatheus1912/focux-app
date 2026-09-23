import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_executar_logic.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';

Aluno _aluno() => Aluno(
  id: 1,
  nome: 'Ana',
  email: 'a@test.com',
  status: 'ATIVO',
);

TreinoExercicioItem _item({double? cargaKg}) => TreinoExercicioItem(
  id: 1,
  exercicio: Exercicio(id: 1, nome: 'Supino'),
  series: 3,
  repeticoes: '10',
  ordem: 1,
  cargaKg: cargaKg,
);

void main() {
  test('CARGA sem kg no treino não oferece CTA de reduzir', () {
    final spec = resolveCopilotExecutarAcao(
      tipoAcao: 'CARGA',
      aluno: _aluno(),
      proxima: const ProximaAcaoResumo(
        acao: 'Reduzir carga do treino',
        motivo: 'Recuperação baixa',
        fonte: 'RECOVERY',
        prioridade: 'P1',
        tipoAcao: 'CARGA',
      ),
      treinoTemCargaNumerica: false,
    );
    expect(spec, isNull);
  });

  test('CARGA com kg continua oferecendo reduzir', () {
    final spec = resolveCopilotExecutarAcao(
      tipoAcao: 'CARGA',
      aluno: _aluno(),
      proxima: const ProximaAcaoResumo(
        acao: 'Reduzir carga do treino',
        motivo: 'Recuperação baixa',
        fonte: 'RECOVERY',
        prioridade: 'P1',
        tipoAcao: 'CARGA',
      ),
      treinoTemCargaNumerica: true,
    );
    expect(spec?.backendTipo, 'REDUZIR_CARGA');
  });

  test('treinoListaTemCargaNumerica detecta kg', () {
    expect(
      treinoListaTemCargaNumerica([
        Treino(id: 1, nome: 'A', exercicios: [_item()]),
      ]),
      isFalse,
    );
    expect(
      treinoListaTemCargaNumerica([
        Treino(id: 2, nome: 'B', exercicios: [_item(cargaKg: 60)]),
      ]),
      isTrue,
    );
  });
}
