import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/chat/utils/aluno_picker_list.dart';

Aluno _aluno({required int id, required String nome, String email = ''}) {
  return Aluno(id: id, nome: nome, email: email, status: 'ATIVO');
}

AlunosHomeBundle _bundle(List<Aluno> alunos) {
  return AlunosHomeBundle(
    alunos: alunos,
    stats: const AlunosStats(
      total: 1,
      totalAtivos: 1,
      totalInadimplentes: 0,
      totalRiscoAlto: 0,
      totalConvites: 0,
    ),
    alertasConfig: AlertasConfiguracao(diasSemTreino: 7, aderenciaMinima: 50),
  );
}

/// Home já visitada e recarregando (ou falhando) — estado real do Riverpod.
Future<AsyncValue<AlunosHomeBundle>> _homeAfterRevisit(
  AlunosHomeBundle first, {
  required bool secondFails,
}) async {
  var calls = 0;
  final pending = Completer<AlunosHomeBundle>();
  final homeProvider = FutureProvider<AlunosHomeBundle>((ref) {
    calls++;
    if (calls == 1) return first;
    if (secondFails) throw Exception('down');
    return pending.future;
  });
  final container = ProviderContainer.test(retry: (_, _) => null);
  container.listen(homeProvider, (_, _) {});
  await container.read(homeProvider.future);
  container.invalidate(homeProvider);
  if (secondFails) {
    await expectLater(container.read(homeProvider.future), throwsException);
  }
  return container.read(homeProvider);
}

void main() {
  final ana = _aluno(id: 1, nome: 'Ana Silva', email: 'ana@test.com');
  final bruno = _aluno(id: 2, nome: 'Bruno Costa', email: 'bruno@test.com');
  final home = _bundle([ana, bruno]);

  group('alunoPickerAlunosFromHome', () {
    test('returns cached alunos from home data', () {
      expect(alunoPickerAlunosFromHome(AsyncData(home)), [ana, bruno]);
    });

    test('returns null while home is loading without cache', () {
      expect(
        alunoPickerAlunosFromHome(const AsyncLoading<AlunosHomeBundle>()),
        isNull,
      );
    });

    test('keeps cached alunos while home refreshes', () async {
      final refreshing = await _homeAfterRevisit(home, secondFails: false);
      expect(refreshing.isLoading, isTrue);
      expect(alunoPickerAlunosFromHome(refreshing), [ana, bruno]);
    });

    test('keeps cached alunos when home errors after a visit', () async {
      final errored = await _homeAfterRevisit(home, secondFails: true);
      expect(errored.hasError, isTrue);
      expect(alunoPickerAlunosFromHome(errored), [ana, bruno]);
    });
  });

  group('filterAlunoPickerAlunos', () {
    test('returns all when query is empty', () {
      expect(filterAlunoPickerAlunos([ana, bruno], '  '), [ana, bruno]);
    });

    test('matches nome or email', () {
      expect(filterAlunoPickerAlunos([ana, bruno], 'bruno'), [bruno]);
      expect(filterAlunoPickerAlunos([ana, bruno], 'ANA@'), [ana]);
    });
  });
}
