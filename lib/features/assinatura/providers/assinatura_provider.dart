import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/payment_api_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/assinatura_repository.dart';
import '../data/plano.dart';

final assinaturaRepositoryProvider = Provider<AssinaturaRepository>(
  (ref) => AssinaturaRepository(
    ref.read(apiClientProvider),
    ref.read(paymentApiClientProvider),
  ),
);

/// First paint do paywall — um GET (`/api/planos/paywall/home`).
final paywallHomeProvider = FutureProvider<PaywallHomeBundle>((ref) async {
  return ref.read(assinaturaRepositoryProvider).getPaywallHome();
});

/// Derivado do BFF — sem GET extra quando [paywallHomeProvider] está fresco.
final planosProvider = FutureProvider<List<Plano>>((ref) async {
  return (await ref.watch(paywallHomeProvider.future)).planos;
});
