import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/perfil_repository.dart';

final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => PerfilRepository(ref.read(apiClientProvider)),
);

final perfilProvider = FutureProvider<PerfilPersonal>((ref) async {
  return ref.read(perfilRepositoryProvider).buscar();
});
