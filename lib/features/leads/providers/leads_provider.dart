import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';

final leadsHomeProvider = FutureProvider<LeadsHomeBundle>((ref) async {
  return LeadRepository(ref.read(apiClientProvider)).getHome();
});

void invalidateLeadsCaches(WidgetRef ref) {
  ref.invalidate(leadsHomeProvider);
}
