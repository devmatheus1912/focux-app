import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_client_cache.dart';

final _aluno = Aluno(
  id: 1,
  nome: 'Ana 360',
  email: 'ana360@test.com',
  status: 'ATIVO',
);


final _bundle = Aluno360(
  aluno: _aluno,
  autonomiaResumo: const AlunoAutonomiaResumo(
    alunoId: 1,
    totalEventos: 0,
    vistos: 0,
    cliques: 0,
    concluidos: 0,
  ),
  timelinePreview: const [],
  proximaAcao: const ProximaAcaoResumo(
    acao: 'Contatar',
    motivo: 'Teste',
    fonte: 'PADRAO',
    prioridade: 'P2',
  ),
  evolucaoInteligente: const EvolucaoInteligente(
    sinal: 'SEM_DADOS',
    resumo: '',
    volumeSemanal: 0,
    volumeMensal: 0,
    proximaAcao: '',
    sugerirCopiloto: false,
  ),
);


void main() {
  tearDown(Aluno360ClientCache.clear);

  test('returns fresh entry within TTL and misses after', () {
    final now = DateTime(2026, 1, 1, 12);
    Aluno360ClientCache.put(1, _bundle, now: now);
    expect(Aluno360ClientCache.getIfFresh(1, now: now), same(_bundle));
    expect(
      Aluno360ClientCache.getIfFresh(
        1,
        now: now.add(const Duration(seconds: 44)),
      ),
      same(_bundle),
    );
    expect(
      Aluno360ClientCache.getIfFresh(
        1,
        now: now.add(const Duration(seconds: 46)),
      ),
      isNull,
    );
  });

  test('invalidate removes entry', () {
    Aluno360ClientCache.put(1, _bundle);
    Aluno360ClientCache.invalidate(1);
    expect(Aluno360ClientCache.getIfFresh(1), isNull);
  });
}
