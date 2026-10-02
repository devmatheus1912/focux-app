import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';

final leadsHomeProvider = FutureProvider<LeadsHomeBundle>((ref) async {
  return LeadRepository(ref.read(apiClientProvider)).getHome();
});

/// Contagem para o teaser do Free. Falha vira `null` (sem teaser, sem toast).
final leadsContagemTeaserProvider = FutureProvider.autoDispose<LeadsContagem?>((
  ref,
) async {
  try {
    return await LeadRepository(ref.read(apiClientProvider)).contagem();
  } catch (_) {
    return null;
  }
});

/// "N leads esperando", ou `null` sem leads/sem dado.
String? leadsTeaserLabel(LeadsContagem? contagem) {
  final n = contagem?.total ?? 0;
  if (n <= 0) return null;
  return n == 1 ? '1 lead esperando' : '$n leads esperando';
}

void invalidateLeadsCaches(WidgetRef ref) {
  ref.invalidate(leadsHomeProvider);
}
