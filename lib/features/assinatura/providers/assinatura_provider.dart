import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/payment_api_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../planos/paywall/paywall_vitrine.dart';
import '../data/assinatura_repository.dart';
import '../data/plano.dart';

final assinaturaRepositoryProvider = Provider<AssinaturaRepository>(
  (ref) => AssinaturaRepository(
    ref.read(apiClientProvider),
    ref.read(paymentApiClientProvider),
  ),
);

final planosProvider = FutureProvider<List<Plano>>((ref) async {
  return ref.read(assinaturaRepositoryProvider).listarPlanos();
});

final paywallVitrineProvider = FutureProvider<PaywallVitrineSnapshot>((
  ref,
) async {
  try {
    return await ref.read(assinaturaRepositoryProvider).fetchVitrine();
  } catch (_) {
    return PaywallVitrineSnapshot.fromCatalog();
  }
});
