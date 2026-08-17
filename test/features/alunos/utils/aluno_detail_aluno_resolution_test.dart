import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno_detail_aluno_resolution.dart';

final _alunoFrom360 = Aluno(
  id: 1,
  nome: 'Ana 360',
  email: 'ana360@test.com',
  status: 'ATIVO',
);

final _alunoFallback = Aluno(
  id: 1,
  nome: 'Ana Fallback',
  email: 'ana@test.com',
  status: 'ATIVO',
);

final _bundle360 = Aluno360(
  aluno: _alunoFrom360,
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
  group('shouldWatchAlunoDetailFallback', () {
    test('false while loading or when 360 has data', () {
      expect(
        shouldWatchAlunoDetailFallback(const AsyncLoading<Aluno360>()),
        isFalse,
      );
      expect(
        shouldWatchAlunoDetailFallback(AsyncData(_bundle360)),
        isFalse,
      );
    });

    test('true only when 360 failed without value', () {
      expect(
        shouldWatchAlunoDetailFallback(
          AsyncError<Aluno360>(Exception('360 down'), StackTrace.current),
        ),
        isTrue,
      );
    });
  });

  group('resolveAlunoDetailAlunoAsync', () {
    test('prefers aluno embedded in 360', () {
      final resolved = resolveAlunoDetailAlunoAsync(
        aluno360Async: AsyncData(_bundle360),
        alunoFallbackAsync: AsyncData(_alunoFallback),
      );
      expect(resolved.hasValue, isTrue);
      expect(resolved.value!.nome, 'Ana 360');
    });

    test('stays loading while 360 loads (no fallback watch)', () {
      final resolved = resolveAlunoDetailAlunoAsync(
        aluno360Async: const AsyncLoading<Aluno360>(),
      );
      expect(resolved.isLoading, isTrue);
      expect(resolved.hasValue, isFalse);
    });

    test('uses alunoProvider fallback when 360 errors', () {
      final resolved = resolveAlunoDetailAlunoAsync(
        aluno360Async: AsyncError(Exception('360'), StackTrace.current),
        alunoFallbackAsync: AsyncData(_alunoFallback),
      );
      expect(resolved.hasValue, isTrue);
      expect(resolved.value!.nome, 'Ana Fallback');
    });

    test('surfaces 360 error when fallback missing', () {
      final error = Exception('360');
      final stack = StackTrace.current;
      final resolved = resolveAlunoDetailAlunoAsync(
        aluno360Async: AsyncError(error, stack),
      );
      expect(resolved.hasError, isTrue);
      expect(resolved.error, same(error));
    });
  });
}
