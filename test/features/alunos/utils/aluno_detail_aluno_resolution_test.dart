import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno_detail_aluno_resolution.dart';
import 'package:focux_app/features/health/data/health_repository.dart';

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


final _operacao = Aluno360Operacao(
  aluno: _alunoFrom360,
  autonomiaResumo: const AlunoAutonomiaResumo(
    alunoId: 1,
    totalEventos: 0,
    vistos: 0,
    cliques: 0,
    concluidos: 0,
  ),
  proximaAcao: const ProximaAcaoResumo(
    acao: 'Contatar',
    motivo: 'Teste',
    fonte: 'PADRAO',
    prioridade: 'P2',
  ),
);

final _recovery = RecoverySnapshot(
  steps: 1000,
  caloriesBurned: 200,
  avgHeartRate: 62,
  sleepHours: 7.5,
  recoveryScore: 80,
  recoveryLabel: 'Bom',
  recoveryHint: 'ok',
);

final _operacaoWithRecovery = Aluno360Operacao(
  aluno: _alunoFrom360,
  autonomiaResumo: _operacao.autonomiaResumo,
  proximaAcao: _operacao.proximaAcao,
  recoverySnapshot: _recovery,
);

final _evolucao = const Aluno360Evolucao(
  evolucaoInteligente: EvolucaoInteligente(
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
        shouldWatchAlunoDetailFallback(const AsyncLoading<Aluno360Operacao>()),
        isFalse,
      );
      expect(shouldWatchAlunoDetailFallback(AsyncData(_operacao)), isFalse);
    });

    test('true only when 360 failed without value', () {
      expect(
        shouldWatchAlunoDetailFallback(
          AsyncError<Aluno360Operacao>(Exception('360 down'), StackTrace.current),
        ),
        isTrue,
      );
    });
  });

  group('shouldWatchAlunoRecoverySidecar', () {
    test('false while 360 is loading', () {
      expect(
        shouldWatchAlunoRecoverySidecar(
          const AsyncLoading<Aluno360Operacao>(),
          tabIndex: 0,
        ),
        isFalse,
      );
    });

    test('false when 360 has bundled recovery', () {
      expect(
        shouldWatchAlunoRecoverySidecar(
          AsyncData(_operacaoWithRecovery),
          tabIndex: 0,
        ),
        isFalse,
      );
    });

    test('never watches recovery sidecar (bundle-only)', () {
      expect(
        shouldWatchAlunoRecoverySidecar(AsyncData(_operacao), tabIndex: 0),
        isFalse,
      );
      expect(
        shouldWatchAlunoRecoverySidecar(
          AsyncError<Aluno360Operacao>(Exception('360 down'), StackTrace.current),
          tabIndex: 0,
        ),
        isFalse,
      );
    });

    test('false on other tabs', () {
      expect(
        shouldWatchAlunoRecoverySidecar(AsyncData(_operacao), tabIndex: 1),
        isFalse,
      );
    });
  });

  group('shouldWatchAluno360Tab1Sidecars', () {
    test('false when evolucao tab not opened yet', () {
      expect(
        shouldWatchAluno360Tab1Sidecars(
          AsyncError<Aluno360Evolucao>(Exception('360 down'), StackTrace.current),
          tabIndex: 1,
          evolucaoTabOpened: false,
        ),
        isFalse,
      );
    });

    test('false while 360 is loading even on tab 1', () {
      expect(
        shouldWatchAluno360Tab1Sidecars(
          const AsyncLoading<Aluno360Evolucao>(),
          tabIndex: 1,
          evolucaoTabOpened: true,
        ),
        isFalse,
      );
    });

    test('false when 360 has value — prefer bundle fields', () {
      expect(
        shouldWatchAluno360Tab1Sidecars(AsyncData(_evolucao), tabIndex: 1, evolucaoTabOpened: true),
        isFalse,
      );
    });

    test('true on tab 1 only after 360 error', () {
      expect(
        shouldWatchAluno360Tab1Sidecars(
          AsyncError<Aluno360Evolucao>(Exception('360 down'), StackTrace.current),
          tabIndex: 1,
          evolucaoTabOpened: true,
        ),
        isTrue,
      );
      expect(
        shouldWatchAluno360Tab1Sidecars(
          AsyncError<Aluno360Evolucao>(Exception('360 down'), StackTrace.current),
          tabIndex: 0,
        ),
        isFalse,
      );
    });
  });

  group('resolveAlunoDetailAlunoAsync', () {
    test('prefers aluno embedded in 360', () {
      final resolved = resolveAlunoDetailAlunoAsync(
        operacaoAsync: AsyncData(_operacao),
        alunoFallbackAsync: AsyncData(_alunoFallback),
      );
      expect(resolved.hasValue, isTrue);
      expect(resolved.value!.nome, 'Ana 360');
    });

    test('stays loading while 360 loads (no fallback watch)', () {
      final resolved = resolveAlunoDetailAlunoAsync(
        operacaoAsync: const AsyncLoading<Aluno360Operacao>(),
      );
      expect(resolved.isLoading, isTrue);
      expect(resolved.hasValue, isFalse);
    });

    test('uses alunoProvider fallback when 360 errors', () {
      final resolved = resolveAlunoDetailAlunoAsync(
        operacaoAsync: AsyncError(Exception('360'), StackTrace.current),
        alunoFallbackAsync: AsyncData(_alunoFallback),
      );
      expect(resolved.hasValue, isTrue);
      expect(resolved.value!.nome, 'Ana Fallback');
    });

    test('surfaces 360 error when fallback missing', () {
      final error = Exception('360');
      final stack = StackTrace.current;
      final resolved = resolveAlunoDetailAlunoAsync(
        operacaoAsync: AsyncError(error, stack),
      );
      expect(resolved.hasError, isTrue);
      expect(resolved.error, same(error));
    });
  });

  group('resolveAlunoDetailListPreview', () {
    test('prefers route preview when id matches', () {
      final preview = resolveAlunoDetailListPreview(
        alunoId: 1,
        routePreview: _alunoFallback,
      );
      expect(preview?.nome, 'Ana Fallback');
    });

    test('ignores route preview with other id', () {
      final other = Aluno(
        id: 99,
        nome: 'Outro',
        email: 'o@test.com',
        status: 'ATIVO',
      );
      final preview = resolveAlunoDetailListPreview(
        alunoId: 1,
        routePreview: other,
      );
      expect(preview, isNull);
    });
  });
}
