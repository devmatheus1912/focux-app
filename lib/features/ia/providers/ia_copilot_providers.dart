import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../health/data/health_repository.dart';
import '../data/ia_repository.dart';
import '../models/ia_copilot_insight.dart';
import '../models/ia_copilot_proxima_acao.dart';
import '../models/ia_copiloto_home.dart';

final iaCopilotoHomeProvider = FutureProvider<IaCopilotoHomeBundle>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).copilotoHome();
});

/// Parameters for the insights provider.
/// Equality + hashCode ensure Riverpod dedupes by (alunoId, mode).
class InsightsQuery {
  final int? alunoId;
  final String? mode;
  const InsightsQuery({this.alunoId, this.mode});

  @override
  bool operator ==(Object other) =>
      other is InsightsQuery && other.alunoId == alunoId && other.mode == mode;

  @override
  int get hashCode => Object.hash(alunoId, mode);
}

final insightsProvider =
    FutureProvider.family<List<IaCopilotInsight>, InsightsQuery>((
      ref,
      query,
    ) async {
      return IaRepository(
        ref.read(apiClientProvider),
      ).insights(alunoId: query.alunoId, mode: query.mode);
    });

final proximaAcaoProvider =
    FutureProvider.family<IaCopilotProximaAcao, int>((ref, alunoId) async {
  return IaRepository(ref.read(apiClientProvider)).proximaAcao(alunoId);
});

final copilotRecoveryProvider = FutureProvider.family<RecoverySnapshot?, int>((
  ref,
  alunoId,
) async {
  return HealthRepository.fromClient(
    ref.read(apiClientProvider),
  ).fetchRecoveryForAluno(alunoId);
});

class IaCopilotTaskDraft {
  const IaCopilotTaskDraft({required this.acao, required this.motivo});

  final String acao;
  final String motivo;
}
