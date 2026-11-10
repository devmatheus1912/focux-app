import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/grupo_aula_repository.dart';

/// Próxima aula em grupo do aluno logado (Home do aluno). Null sem inscrição.
final minhaProximaAulaProvider = FutureProvider.autoDispose<GrupoAula?>(
  (ref) => GrupoAulaRepository(ref.read(apiClientProvider)).minhaProxima(),
);
