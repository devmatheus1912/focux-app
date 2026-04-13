import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/assinatura_repository.dart';

final assinaturaRepositoryProvider = Provider<AssinaturaRepository>(
  (ref) => AssinaturaRepository(ref.read(apiClientProvider)),
);

final planosProvider = FutureProvider<List<Plano>>((ref) async {
  return ref.read(assinaturaRepositoryProvider).listarPlanos();
});
