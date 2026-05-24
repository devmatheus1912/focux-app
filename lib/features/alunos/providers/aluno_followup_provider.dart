import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../alertas/data/alertas_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import 'alunos_provider.dart';

final alertasConfigProvider = FutureProvider<AlertasConfiguracao>((ref) async {
  return AlertasRepository(ref.read(apiClientProvider)).getConfiguracao();
});

final alunosStatsProvider = FutureProvider<AlunosStats>((ref) async {
  return ref.read(alunoRepositoryProvider).buscarStats();
});

class AlunoFollowUpActions {
  AlunoFollowUpActions(this._ref);

  final Ref _ref;

  AlunoRepository get _repo => _ref.read(alunoRepositoryProvider);

  Future<void> snooze(int alunoId, {Duration duration = const Duration(hours: 24)}) async {
    final until = DateTime.now().add(duration);
    await _repo.atualizarFollowUp(
      alunoId,
      snoozedUntil: until.toIso8601String(),
    );
    _invalidate(alunoId);
  }

  Future<void> setFollowUpDate(int alunoId, DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final iso =
        '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
    await _repo.atualizarFollowUp(alunoId, proximoContato: iso, clearSnooze: true);
    _invalidate(alunoId);
  }

  Future<void> clearFollowUp(int alunoId) async {
    await _repo.atualizarFollowUp(
      alunoId,
      clearFollowUp: true,
      clearSnooze: true,
    );
    _invalidate(alunoId);
  }

  Future<void> markContactDone(int alunoId) async {
    await _repo.marcarContatoRealizado(alunoId);
    _invalidate(alunoId);
  }

  void _invalidate(int alunoId) {
    _ref.invalidate(alunosProvider);
    _ref.invalidate(alunosStatsProvider);
    _ref.invalidate(alunoProvider(alunoId));
  }
}

final alunoFollowUpActionsProvider = Provider(AlunoFollowUpActions.new);
