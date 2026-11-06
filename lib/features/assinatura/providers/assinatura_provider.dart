import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/sessao_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/assinatura_repository.dart';

final assinaturaRepositoryProvider = Provider<AssinaturaRepository>(
  (ref) => AssinaturaRepository(ref.read(apiClientProvider)),
);

/// First paint do paywall — um GET (`/api/planos/paywall/home`).
final paywallHomeProvider = FutureProvider<PaywallHomeBundle>((ref) async {
  ref.watch(sessaoProvider);
  return ref.read(assinaturaRepositoryProvider).getPaywallHome();
});

/// Derivado do BFF — sem GET extra quando [paywallHomeProvider] está fresco.
