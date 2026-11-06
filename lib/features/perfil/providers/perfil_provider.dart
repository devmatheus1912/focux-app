import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/sessao_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/perfil_repository.dart';

final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => PerfilRepository(ref.read(apiClientProvider)),
);

final perfilProvider = FutureProvider<PerfilPersonal>((ref) async {
  ref.watch(sessaoProvider);
  return ref.read(perfilRepositoryProvider).buscar();
});

final perfilWalletProvider = FutureProvider<PerfilPersonal>((ref) async {
  ref.watch(sessaoProvider);
  return ref.read(perfilRepositoryProvider).buscar(incluirResumoMensal: true);
});
