import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/assinatura_repository.dart';

final assinaturaRepositoryProvider = Provider<AssinaturaRepository>(
  (ref) => AssinaturaRepository(ref.read(apiClientProvider)),
);

/// First paint do paywall — um GET (`/api/planos/paywall/home`).
final paywallHomeProvider = FutureProvider<PaywallHomeBundle>((ref) async {
  return ref.read(assinaturaRepositoryProvider).getPaywallHome();
});

/// Derivado do BFF — sem GET extra quando [paywallHomeProvider] está fresco.
