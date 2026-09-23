import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aluno_repository.dart';
import 'aluno_detail_providers.dart';
import 'alunos_provider.dart';

class AlunoFollowUpActions {
  AlunoFollowUpActions(this._ref);

  final Ref _ref;

  AlunoRepository get _repo => _ref.read(alunoRepositoryProvider);

  Future<void> snooze(
    int alunoId, {
    Duration duration = const Duration(hours: 24),
  }) async {
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
    await _repo.atualizarFollowUp(
      alunoId,
      proximoContato: iso,
      clearSnooze: true,
    );
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

  Future<Aluno> markContactDone(int alunoId) async {
    final updated = await _repo.marcarContatoRealizado(alunoId);
    _invalidate(alunoId);
    return updated;
  }

  /// Chat send já é o contato — ack de follow-up não pode falhar o envio
  /// nem depender do ciclo de vida do widget (usa [Ref] do Provider).
  Future<void> markContactDoneBestEffort(int alunoId) async {
    try {
      await markContactDone(alunoId);
    } catch (_) {
      // Best-effort: mensagem já foi entregue.
    }
  }

  void _invalidate(int alunoId) {
    invalidateAlunosCachesRef(_ref);
    _ref.invalidate(alunoProvider(alunoId));
    _ref.invalidate(aluno360Provider(alunoId));
    _ref.invalidate(aluno360OperacaoBundleProvider(alunoId));
  }
}

final alunoFollowUpActionsProvider = Provider(AlunoFollowUpActions.new);
